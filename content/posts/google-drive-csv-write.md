---
title: google drive csv　 オブジェクトからcsv ファイルがない場合保存
description: 'Google Apps Scriptでオブジェクトから生成したCSVを、同名ファイルの重複を避けつつGoogle Driveへ保存するコード'
date: 2024-03-06T00:00:00.000Z
image: ''
tags:
  - GCP
  - IT
categories:
  - IT
---

 
```javascript

const sample = { id:1 ,name:"aa"} // サンプル実際のデータに直して

const fileName = "test.csv"



const blob = createBlob(csv, fileName)

deleteAndWriteDrive(blob, folderId, fileName)

function deleteAndWriteDrive(csvBlob, folderId,fileName) {
  const drive = DriveApp.getFolderById(folderId);
  const files = drive.getFiles();
  let sortFiles = []
  while (files.hasNext()) {
    sortFiles.push(files.next());
  }
  sortFiles.sort(function (a, b) { if (a.getName() > b.getName()) { return 1 } else { return -1 } })

  for (const iterator of sortFiles) {
    const file = iterator;
    if (file.getName() === fileName) {
      hasFileName = file.getName()
      console.log(`${hasFileName}フォルダが存在します。`)
      file.setTrashed(true)
      break
    }
  }
  
  drive.createFile(csvBlob);
}

function createBlob(csv, fileName) {
  const contentType = 'text/csv';
  const charset = 'utf-8';
  const blob = Utilities.newBlob('', contentType, fileName).setDataFromString(csv, charset);
  return blob;
}

```

