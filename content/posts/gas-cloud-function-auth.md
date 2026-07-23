---
title: Google App Script から Could Functions を実行するために
description: 'Google Apps ScriptからCloud Functionsを呼び出す際のOAuth認証設定を簡易なやり方でまとめたメモ'
date: 2024-11-01T00:00:00.000Z
image: ''
tags:
  - IT
  - Google App script
  - GCP
  - Cloud Function
categories:
  - IT
---

 
### 経緯



Google App Scriptだけでは外部ライブラリを使ったりnpmを使ったりするのが難しいの


Cloud Functions で処理してデータを返してもらって作ろうと思った時の認証について


ひとまず簡易なやり方で


## 結論

- GCPでOAuth 同意画面を作成
- Google App Script側をOAuth 同意画面作ったGCPプロジェクト作成
- appscript.jsonの編集してOAuthスコープの設定

あと下記のようなコードで認証できる


```javascript

function myFunction() {
  const url = "https://xxxxxx.cloudfunctions.net/xxxxx"
  const res = UrlFetchApp.fetch(url, {
    headers: {
      Authorization: `Bearer ${ScriptApp.getIdentityToken()}`
    }
  })
  console.log(res.getContentText()) // Fnctiionの結果
}


```




[GAS（GoogleAppsScript）から認証付きのCloud Functionsをサービスアカウントを使用して呼び出す #GoogleCloud - Qiita](https://qiita.com/venect_qiita/items/26634a32037e40a585089%C2%A5)
[GASから認証付きのCloud Functionsを実行する。 #GoogleCloud - Qiita](https://qiita.com/kyhei_0727/items/d6b1cb33ce90b99e8129#oauth%E5%90%8C%E6%84%8F%E7%94%BB%E9%9D%A2%E3%81%AE%E4%BD%9C%E6%88%909%C2%A5)


[Google Apps Script (GAS) から Cloud Functions に認証付きでアクセスする – kkuchima memo](https://kkuchima.wordpress.com/2020/12/30/google-apps-script-gas-%E3%81%8B%E3%82%89-cloud-functions-%E3%81%AB%E3%82%A2%E3%82%AF%E3%82%BB%E3%82%B9%E3%81%99%E3%82%8B/9%C2%A5)


[Google Apps Script で書かれたアドオンのバックエンドを Cloud Run に移行した話 - Link and Motivation Developers' Blog](https://link-and-motivation.hatenablog.com/entry/2024/04/10/1200009%C2%A5)


[GAS + CloudFunctionsでVisionAPIの処理結果をスプレッドシートに出力する #GoogleAppsScript - Qiita](https://qiita.com/akira-yp/items/e3cd9d4eefb8f5238edb9%C2%A5)

