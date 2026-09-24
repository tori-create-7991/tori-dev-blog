---
title: Docker DesktopからColima移行してKali Linux(VNC)構築した話
date: 2026-09-03T00:00:00.000Z
platform: x
---

1/6
Docker DesktopをやめてColima(cpu4/mem8/disk30)に移行し、pentest/CTF学習用にKali Linux(VNC構成)のコンテナを構築した。Before: Docker Desktop常駐でKali無し。After: Colima+Docker Desktop終了、VNC経由でXFCE+kali-linux-defaultが使える状態。

2/6
最初にハマったのは`printf ... | vncpasswd`でexit 141(SIGPIPE)。TightVNCのvncpasswdは3行目のview-only確認入力が不要でEOFで自動スキップされる仕様だった。渡す行を2行に減らしたら解決。

3/6
次に`set -euo pipefail`下で`tr ... | head -c 8`が再度exit 141。headが先に入力を閉じて上流のtrがSIGPIPEで死ぬ典型パターン。`|| true`を足して解決した。

4/6
さらに`vncserver ... -fg`でexit 255。TightVNC 1.3.10は`-fg`非対応(TigerVNCの新しめのオプション)だと判明。`tail -F`でプロセスをフォアグラウンド維持する方式に切り替えた。

5/6
AIレビュー(SRE視点)からosascriptのアプリ名指定に「must」指摘が入ったが、`id of application`で実機検証したらfalse positiveだった。AIの指摘も実機で裏取りする価値があると再確認。

6/6
学び: pipefail環境での`head -c N`は上流コマンドをSIGPIPEで巻き込む罠になりやすい。`|| true`で防御するか設計を見直す。AIレビューの指摘は鵜呑みにせず実機検証で裏取りする。
