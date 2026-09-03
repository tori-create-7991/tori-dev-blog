---
title: Docker DesktopからColima移行してKali Linux(VNC)構築した話
date: 2026-09-03T00:00:00.000Z
platform: bluesky
---

Docker DesktopをやめてColima(cpu4/mem8/disk30)に移行し、pentest/CTF学習用にKali Linux(VNC構成)のコンテナを構築した。Docker Desktop常駐+Kali無し→Colima+Docker Desktop終了、VNC経由でXFCE+kali-linux-defaultが使える状態に。

途中でハマったのが3件。`printf ... | vncpasswd`がexit 141(SIGPIPE)、原因はTightVNCのvncpasswdが3行目のview-only確認入力を省略可能でEOFスキップする仕様だったこと(2行に削減で解決)。`set -euo pipefail`下の`tr ... | head -c 8`も同様にexit 141、headが先に入力を閉じ上流trが死ぬ罠で`|| true`で解決。`vncserver ... -fg`はexit 255、TightVNC 1.3.10は`-fg`非対応(TigerVNCのオプション)と判明し`tail -F`でフォアグラウンド維持に変更した。

AIレビュー(SRE視点)のosascriptアプリ名指摘(must)も、実機の`id of application`検証でfalse positiveと判明。

学び: pipefail+`head -c N`の組み合わせは上流をSIGPIPEで巻き込む罠になりやすい。AIレビューの指摘も実機検証で裏取りする価値がある。
