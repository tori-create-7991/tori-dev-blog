---
title: Docker DesktopからColima移行してKali Linux(VNC)構築した話
date: 2026-09-03T00:00:00.000Z
platform: instagram
---

![](/feed/colima-kali-vnc.png)

Docker DesktopをやめてColima(cpu4/mem8/disk30)に移行し、pentest/CTF学習用にKali Linux(VNC構成)のコンテナを構築した。

Docker Desktopは常時GUIアプリが動く方式で、Kali環境も無かった。Colima移行後はDocker Desktopを終了し、docker-composeで立てたKali VNCコンテナに127.0.0.1:5901だけをbindしてアクセスする構成にした。データはnamed volumeで永続化している。

途中でvncpasswdのexit 141(SIGPIPE)や`vncserver -fg`のexit 255(オプション非対応)など複数のエラーにぶつかり、1つずつ原因を切り分けて潰した。今はVNC経由でXFCE+pentestツール一式が使える状態。
