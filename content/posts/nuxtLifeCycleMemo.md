---
title: nuxtライフサイクルmemo
description: 'NuxtのasyncData・created・mounted・computed・watchなどライフサイクルの挙動を整理したメモ'
date: 2021-11-10T00:00:00.000Z
image: ''
tags:
  - IT
  - nuxt
categories:
  - IT
---

 - asyncDataはssaのときはクライアントでssgのときはgenerate時にしかできない
- 以下はクライアントで動く
	- created：インスタンス初期化時、DOMが生成される前
	- mounted：インスタンス初期化時、DOMが生成された後
- computed： 算出プロパティ**getter,setterが使える**
- watch：**データの変化をトリガにしたフック**
