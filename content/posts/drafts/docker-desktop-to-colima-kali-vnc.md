---
title: Docker DesktopからColimaへ移行してKali Linux VNC環境を作った話
description: 'vncpasswdのSIGPIPEからAIレビューのfalse positive発覚まで、6つのバグと格闘した記録'
date: 2026-09-03T00:00:00.000Z
image: ''
tags:
  - Docker
  - Colima
  - Kali Linux
  - VNC
categories:
  - IT
---

## 状況

Docker Desktop常駐でDockerコンテナを運用していたのをColimaに移行しつつ、pentest/CTF学習用にKali Linux(VNC構成)のコンテナを作ることにした。GUIでKaliのデスクトップ環境まで使える状態を目指した。

まずGUI方式をどうするか調べた。候補はX11 forwarding・VNC・colima-ui・x11dockerの4つ。調べていくとcolima-uiはColima自体のコンテナ管理GUIであってKaliのデスクトップとは別物と判明し、x11dockerはmacOS非対応と判明した。残った選択肢のうち安定性を優先してVNC採用に決めた。Docker Desktopは併存させずに終了する方針にした(リソース競合を避けたかった)。

## 遭遇した問題(実ログ)

ここから先はほぼバグとの格闘だった。1つ解決するたびに次が出てくる展開が続いた。

### 1. vncpasswdがSIGPIPEでクラッシュループ

パスワード設定に

```
printf '%s\n%s\nn\n' "$PASSWORD" "$PASSWORD" | vncpasswd "$PASSWD_FILE"
```

を使ったところ、コンテナがexit 141で落ち続けた。141はSIGPIPE(128+13)。

原因を調べると、TightVNCのvncpasswdはview-only設定を聞く3行目の入力(`n`)が不要で、パスワード確認の2行を渡した時点でプロンプトが閉じ、そこにさらに書き込もうとしたprintf側がSIGPIPEで死ぬ仕様だった。3行目のEOFは自動的にスキップされる。渡す行を2行に削減して解決した。

### 2. USER環境変数が未設定

```
vncserver: The USER environment variable is not set.
```

Dockerコンテナ内はデフォルトでUSER環境変数が設定されていない。Dockerfileに `ENV USER=root` を追加して解決した。

### 3. デフォルトフォントが開けない

```
Fatal server error: could not open default font 'fixed'
```

`apt-get install --no-install-recommends` でインストールした際、`xfonts-base` パッケージが依存関係から外れて漏れていたのが原因。明示的に追加インストールして解決した。

### 4. -fgオプションがexit 255で謎の失敗

`vncserver ... -fg` を実行するとexit 255になり、usageメッセージが出力される謎の失敗に遭遇した。

調べると、コンテナに入っていたTightVNC 1.3.10は `-fg`(foreground)オプション非対応だった。これはTigerVNCの方に後から追加されたオプションで、TightVNCには存在しない。ドキュメントだけを見て判断していたら気づけなかった罠で、実際に動かして初めて分かった。

対処として、vncserverはデーモン化させたうえで `tail -F <logfile>` をexecし、それをコンテナのフォアグラウンドプロセスとして維持する方式に変更した。

### 5. ランダムパスワード生成がまたSIGPIPEでクラッシュ

```
PASSWORD="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 8)" 
```

を `set -euo pipefail` 下で実行すると、これも再びexit 141のクラッシュループになった。

`head -c 8` は8バイト読んだ時点でパイプの読み込み側を閉じる。すると上流の `tr` は書き込み先が閉じられたことでSIGPIPEを受けて終了する。これ自体はUnixパイプラインとして正常な挙動だが、`pipefail` が有効だとパイプライン全体の終了ステータスとしてそのSIGPIPEが拾われてしまう。generator | head -c N という組み合わせでpipefailを使うと踏みやすい典型的な罠だった。パイプ末尾に `|| true` を追加して解決した。

### 6. docker-compose.ymlのtty設定でvncpasswdがハング

`docker-compose.yml` に `stdin_open: true` / `tty: true` を設定した状態だと、vncpasswdプロセスが標準入力待ちで無期限にハングした。`docker exec` で `ps aux` を確認すると、vncpasswdプロセスが `State S+` のまま残っていた。これらの設定を削除して解決した。

### 番外: nmapのraw socketが権限エラー

VNC環境が動いたあと、実際にnmapを叩くと

```
Operation not permitted
```

で失敗した。Dockerのデフォルトcapabilitiesではnmapのraw socket作成に必要な `CAP_NET_RAW` が付与されていない。`docker-compose.yml` に

```yaml
cap_add:
  - NET_RAW
  - NET_ADMIN
```

を追加して解決した。

### 番外: AIレビューのfalse positiveを実機検証で発見

一連の作業とは別セッション(00_my_env側)でのPRレビューで、SRE役のAIレビューから「`osascript -e 'tell application "Docker Desktop" to quit'` のアプリ名が誤りで、正しくは"Docker"」というmust指摘を受けた。

鵜呑みにせず実機で確認することにした。

```
osascript -e 'id of application "Docker Desktop"'
```

を実行すると `com.electron.dockerdesktop` が正しく返ってきた。つまり指摘は誤りで、アプリ名"Docker Desktop"はそのまま正しかった。AIレビューのmust判定であっても、可能なら実機検証で裏取りする価値があると実感した一件だった。

## 解決

最終的にColima(cpu4/mem8/disk30、aarch64)上でDocker Desktopを終了した状態からCLI運用に移行し、`vnc://localhost:5901` 経由でXFCEデスクトップ + kali-linux-default一式(nmap等)が使えるpentest学習環境が実際に稼働するところまで持っていけた。VNCパスワードはビルド時に埋め込まず、entrypoint.shで環境変数が指定されていればそれを優先、未指定ならランダム生成する方式にした。永続化はnamed volumeで`/root`をマウントしている。

00_my_env側のPRレビューは4専門家×3ラウンドで延べ約10回のサブエージェント実行、修正コミットは5件になった。

## 学び

- `set -o pipefail` 下で `generator | head -c N` のような組み合わせを使うと、`head` が先に読み込みを打ち切ることで上流がSIGPIPEで死に、それをpipefailが拾ってしまう。`|| true` を末尾に付けるのを忘れない
- TightVNCのようなツールはバージョンによってオプション対応状況が違う(`-fg` はTigerVNCのオプションでTightVNC 1.3.10には無い)。ドキュメントの記載だけで判断せず、実際に動かして確認すべき
- AIレビューの指摘、特にmust判定であっても鵜呑みにしない方がいい。今回は実機で `osascript -e 'id of application "..."'` を叩いて確認したことで、false positiveだと分かった
