---
title: 楽天payと楽天キャッシュの入出金を毎日GAS(google app script)で取得してみる
description: 'Google Apps ScriptでGmailを自動解析し、楽天Pay・楽天キャッシュの利用履歴をスプレッドシートに毎日記録するスクリプトを作った話'
date: 2024-12-11T00:00:00.000Z
image: ''
tags:
  - Javascript
  - Google App script
categories:
  - IT
---

 
# Gmailを自動解析！楽天Payと楽天キャッシュの利用情報をスプレッドシートに記録するスクリプト


## はじめに


日々の支出管理やキャッシュフローの可視化は大切ですよね？


僕は基本的に支払いは電子決済で済ませてるので大体の履歴はマネーフォワードに連携して


そこで見ているですが、実は楽天pay,PayPay,ANApayなどは連携していなく


アプリでしかみることができないので今回
「楽天Pay」や「楽天キャッシュ」の利用履歴を自動で取得して、スプレッドシートに保存してBIで見れたら便利だと思いやってみました
今回は **Google Apps Script (GAS)** を使って、Gmailから自動で利用情報を取得し、Googleスプレッドシートに記録するスクリプトを作成します。


また、基本的に楽天payの支払いを楽天キャッシュからしているので支払いとチャージ料方法を取得するコードもつくりました。


---


## 1. 楽天Pay版スクリプト



- Gmailの「楽天Payアプリご利用内容確認メール」を解析。
- 利用日時、店舗名、伝票番号、決済総額などを抽出。
- データをGoogleスプレッドシートに自動で記録。


```javascript


function checkRakutenPayEmailsAndLogDaily() {
  const sheetId = "YOUR_SPREADSHEET_ID"; // スプレッドシートIDを指定
  const sheetName = "楽天Payログ"; // シート名を指定

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const yesterday = new Date(today);
  yesterday.setDate(today.getDate() - 1);
  const startDate = Utilities.formatDate(yesterday, Session.getScriptTimeZone(), "yyyy/MM/dd");
  const endDate = Utilities.formatDate(today, Session.getScriptTimeZone(), "yyyy/MM/dd");

  const searchQuery = `from:no-reply@pay.rakuten.co.jp subject:"楽天ペイアプリご利用内容確認メール" after:${startDate} before:${endDate}`;
  const sheet = SpreadsheetApp.openById(sheetId).getSheetByName(sheetName);
  if (!sheet) throw new Error(`シート "${sheetName}" が見つかりません`);

  const threads = GmailApp.search(searchQuery);
  if (threads.length === 0) {
    console.log("前日分の対象メールはありません。");
    return;
  }

  threads.forEach(thread => {
    const messages = thread.getMessages();
    messages.forEach(message => {
      const body = message.getPlainBody();
      let date, receiptNumber, store, totalAmount, points, paymentMethod;

      const dateMatch = body.match(/ご利用日時\s+([\d/]+\(.\)\s+[\d:]+)/);
      const receiptMatch = body.match(/伝票番号\s+([A-Z0-9-]+)/);
      const storeMatch = body.match(/ご利用店舗\s+(.+)/);
      const totalAmountMatch = body.match(/決済総額\s+¥([\d,]+)/);
      const pointsMatch = body.match(/ポイント\s+([\d,]+)/);
      const paymentMatch = body.match(/お取引内容\s+(.+)/);

      date = dateMatch ? dateMatch[1] : "不明";
      receiptNumber = receiptMatch ? receiptMatch[1] : "不明";
      store = storeMatch ? storeMatch[1].trim() : "不明";
      totalAmount = totalAmountMatch ? totalAmountMatch[1].replace(/,/g, '') : "0";
      points = pointsMatch ? pointsMatch[1] : "0";
      paymentMethod = paymentMatch ? paymentMatch[1].trim() : "不明";

      sheet.appendRow([new Date(), date, receiptNumber, store, `¥${totalAmount}`, points, paymentMethod]);
    });
  });

  console.log("前日分の楽天ペイのメール内容をスプレッドシートに記録しました。");
}

```


---


## 2. 楽天キャッシュ版スクリプト

- Gmailの「楽天キャッシュチャージ完了メール」を解析。
- 取引日時、チャージ内容、金額を抽出。
- データをGoogleスプレッドシートに自動で記録。

### スクリプトコード


```javascript
function checkRakutenCashEmailsAndLogDaily() {
  const sheetId = "YOUR_SPREADSHEET_ID"; // スプレッドシートIDを指定
  const sheetName = "楽天キャッシュログ"; // シート名を指定

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const yesterday = new Date(today);
  yesterday.setDate(today.getDate() - 1);
  const startDate = Utilities.formatDate(yesterday, Session.getScriptTimeZone(), "yyyy/MM/dd");
  const endDate = Utilities.formatDate(today, Session.getScriptTimeZone(), "yyyy/MM/dd");

  const searchQuery = `from:pointcharge@edy.rakuten.co.jp subject:"【楽天キャッシュ】チャージ完了のお知らせ" after:${startDate} before:${endDate}`;
  const sheet = SpreadsheetApp.openById(sheetId).getSheetByName(sheetName);
  if (!sheet) throw new Error(`シート "${sheetName}" が見つかりません`);

  const threads = GmailApp.search(searchQuery);
  if (threads.length === 0) {
    console.log("前日分の対象メールはありません。");
    return;
  }

  threads.forEach(thread => {
    const messages = thread.getMessages();
    messages.forEach(message => {
      const body = message.getPlainBody();
      let transactionDate, content, amount;

      const dateMatch = body.match(/\[取引日時\]\s+([\d/]+\s+[\d:]+)/);
      const contentMatch = body.match(/\[内容\]\s+(.+)/);
      const amountMatch = body.match(/\[金額\]\s+([\d,]+)円/);

      transactionDate = dateMatch ? dateMatch[1] : "不明";
      content = contentMatch ? contentMatch[1].trim() : "不明";
      amount = amountMatch ? amountMatch[1].replace(/,/g, '') : "0";

      sheet.appendRow([new Date(), transactionDate, content, `¥${amount}`]);
    });
  });

  console.log("前日分の楽天キャッシュのメール内容をスプレッドシートに記録しました。");
}

```


---


## 3. トリガー設定


どちらのスクリプトも毎日自動実行するには、Google Apps Script の **トリガー機能** を活用します。

1. スクリプトエディタを開き、時計マーク（トリガー設定）をクリック。
2. 「トリガーを追加」を選択。
3. 必要なスクリプト関数（例: `checkRakutenPayEmailsAndLogDaily`）を選択。
4. 実行タイミングを「日付ベース」「午前1時」などに設定。

---


## 終わりに


これで、毎日の支出やチャージ状況を取得できそうです。


これを元にBIなどでみるかもしくはマネーフォワードに自動的にスクレイピングのライブラリを使って登録するのもいいかもしれません。

