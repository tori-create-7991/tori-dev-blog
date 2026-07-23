---
title: google drive csv 取込結合 スプレッドシート書き込み
description: 'Google Apps ScriptでGoogle Driveフォルダ内のCSVファイルをまとめて読み込み、スプレッドシートに書き込むコード'
date: 2024-08-08T00:00:00.000Z
image: ''
tags:
  - GCP
  - IT
categories:
  - IT
---

 
```javascript
function importData() {

  // 対象フォルダを指定
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("data"); //シート名
  const folder = DriveApp.getFolderById('xxxxx'); //フォルダパスを指定



  sheet.getRange(2, 1, sheet.getLastRow(), sheet.getLastColumn()).clear()

  const files = folder.getFiles();
  let sortFiles = []
  while (files.hasNext()) {
    sortFiles.push(files.next());
  }
  sortFiles.sort(function (a, b) { if (a.getName() > b.getName()) { return 1 } else { return -1 } })


  let allSetData = []
  for (const iterator of sortFiles) {
    const file = iterator;
    // 取込処理
    const data = file.getBlob().getDataAsString("UTF-8");
    const csv = Utilities.parseCsv(data);
    const setData = csv
    setData.shift()
    setData.reverse()
    const lastRow = sheet.getLastRow();
    Logger.log(setData)

    allSetData = [...allSetData, ...setData]
    // CSV書込
    if (setData.length > 0) sheet.getRange(lastRow + 1, 1, setData.length, setData[0].length).setValues(setData);


```

