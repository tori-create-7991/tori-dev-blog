---
title: NotionタスクとGoogleカレンダーの同期システムを作る
description: 'Notionのタスクの期限日をGoogleカレンダーへ自動同期し、完了タスクは別カレンダーへ移すシステムの実装方法'
date: 2024-11-03T00:00:00.000Z
image: ''
tags:
  - IT
  - Google App script
  - Notion
  - Javascript
  - Google Calender
categories:
  - IT
---

 
## はじめに


NotionのタスクをGoogleカレンダーと自動で同期させるシステムの実装方法を紹介します。このシステムにより、Notionで管理しているタスクの期限日を自動的にGoogleカレンダーに反映させることができます。ただしGoogleカレンダーの変更をNotionに反映することは想定していません。


また、完了したタスクはGoogleカレンダータスクを同期しているカレンダーとは別のカレンダに移動させるようにしています。


## システムの概要


### 主な機能

- Notionの新規タスクを自動的にGoogleカレンダーに追加
- タスクの更新（タイトル、期限）をカレンダーに反映
- 完了したタスクのカレンダーイベントを自動削除
- 定期的に同期

### 必要な準備

1. Notion API キー
2. Notionデータベースの設定
3. Googleカレンダー
4. Google Apps Script環境

## 実装方法


### 1. 設定


必要な認証情報とIDを設定します：


```javascript
const CONFIG = {
  NOTION_API_KEY: 'your-notion-api-key',
  NOTION_DATABASE_ID: 'your-database-id',
  CALENDAR_ID: 'your-calendar-id@group.calendar.google.com',
  DONE_CALENDAR_ID: 'your-calendar-id@group.calendar.google.com',
  NOTION_VERSION: '2022-06-28'
};
```


### 2. Notionとの連携


### タスク取得


```javascript
// Notionからタスク一覧を取得
function getNotionTasks() {
  const url = `https://api.notion.com/v1/databases/${CONFIG.NOTION_DATABASE_ID}/query`;
  const response = UrlFetchApp.fetch(url, {
    method: 'POST',
    headers: NOTION_HEADERS,
    payload: JSON.stringify({
      sorts: [
        {
          property: 'DueDate', // 日付プロパティ名
          direction: 'descending' // 昇順にソート（降順の場合は'descending'に変更）
        }
      ],
    })
  });

```


### タスク更新


```javascript
// Notionのタスクを更新（カレンダーイベントIDの保存）
function updateNotionTask(taskId, calendarEventId) {
  const url = `https://api.notion.com/v1/pages/${taskId}`;
  return UrlFetchApp.fetch(url, {
    method: 'PATCH',
    headers: NOTION_HEADERS,
    payload: JSON.stringify({
      properties: {
        'Calendar Event ID': {
          rich_text: [{
            text: { content: calendarEventId }
          }]
        }
      }
    })
  });
}

```


### 3. Googleカレンダーとの連携


### イベント作成


```javascript
function createCalendarEvent(task) {
  const calendar = CalendarApp.getCalendarById(CONFIG.CALENDAR_ID);
  const title = task.properties.Name.title[0].plain_text;
  const dueDate = new Date(task.properties.DueDate.date.start);

  const event = calendar.createAllDayEvent(
    title,
    dueDate,
    { description: `Notion Task ID: ${task.id}\\nURL: ${task.url}` }
  );

  return event.getId();
}

```


### 4. 状態管理


タスクの状態を管理するための機能：


```javascript

// タスクの現在の状態を取得
function getTaskState(task) {
  return {
    id: task.id,
    title: task.properties.Name.title[0].plain_text,
    dueDate: task.properties.DueDate.date?.start,
    status: task.properties.Status.status ? task.properties.Status.status.name : "None",
    calendarEventId: task.properties['Calendar Event ID']?.rich_text[0]?.text.content
  };
}

```


### 5. メイン同期処理


```javascript
function syncNotionWithCalendar() {
  try {
    const tasks = getNotionTasks();
    const previousState = getPreviousState();
    const currentState = {};

    tasks.forEach(task => {
      currentState[task.id] = getTaskState(task);
    });

    tasks.forEach(task => {
      processTaskChanges(task, previousState, currentState);
    });

    processDeletedTasks(previousState, currentState);
    savePreviousState(currentState);

  } catch (error) {
    logError(error, 'メイン同期処理');
  }
}

```


## 実装のポイント


### 1. エラーハンドリング

- 各処理でtry-catchを使用
- エラーログの記録
- コンテキスト情報の保持

### 2. キャッシュの活用

- 前回の状態をキャッシュに保存
- 6時間のキャッシュ有効期限
- 差分検出による効率的な更新

### 3. 定期実行の設定


```javascript
// 定期実行トリガーの設定
function setUpTrigger() {
  // 既存のトリガーを削除
  ScriptApp.getProjectTriggers().forEach(trigger => {
    ScriptApp.deleteTrigger(trigger);
  });

  // 新しいトリガーを作成（1時間ごとに実行）
  ScriptApp.newTrigger('syncNotionWithCalendar')
    .timeBased()
    .everyHours(1)
    .create();
}

```


## Notionデータベースの設定


きちんとtextかstatusか日付か合わせる


必要な項目：

1. Name（タイトル）
2. DueDate（期限日）
3. Status（ステータス）
4. Calendar Event ID（カレンダー連携用）

## セットアップ手順

1. Google Apps Scriptプロジェクトの作成
2. Notion APIキーの取得
	1. Notion APIキーは [Notion Developer](https://www.notion.so/my-integrations) から取得できます。
3. Notionデータベースの準備
	1. 同期したいデータベースのURLから、IDを取得します。
4. **GoogleカレンダーID**を確認する。
	- メインカレンダーの場合は`primary`、他のカレンダーの場合はカレンダー設定画面でIDを確認してください。
5. コードの貼り付けと設定
6. トリガーの設定
	1. setUpTriggerの実行 自分の頻度に合わせて
7. **権限の設定**
	- 初回実行時にGoogleカレンダーへのアクセス権限を求められますので、許可します。

```javascript
// API キーやIDを管理する設定オブジェクト
const CONFIG = {
  NOTION_API_KEY: 'your-notion-api-key',
  NOTION_DATABASE_ID: 'your-database-id',
  CALENDAR_ID: 'your-calendar-id@group.calendar.google.com',
  DONE_CALENDAR_ID: 'your-calendar-id@group.calendar.google.com',
  NOTION_VERSION: '2022-06-28'
};

// Notionの共通ヘッダー設定
const NOTION_HEADERS = {
  'Authorization': `Bearer ${CONFIG.NOTION_API_KEY}`,
  'Notion-Version': CONFIG.NOTION_VERSION,
  'Content-Type': 'application/json'
};





// メイン同期処理
function syncNotionWithCalendar() {
  try {
    // タスク一覧の取得
    const tasks = getNotionTasks();
    const previousState = getPreviousState();
    const currentState = {};

    // 現在の状態を構築
    console.log("現在の状態を構築")
    tasks.forEach(task => {

      currentState[task.id] = getTaskState(task);
    });

    console.log("タスクの変更を処理")
    // タスクの変更を処理
    tasks.forEach(task => {
      console.log("currentState", currentState[task.id])
      console.log("previousState", previousState[task.id])
      processTaskChanges(task, previousState, currentState);
    });

    // 削除されたタスクを処理
    console.log("削除されたタスクを処理")
    processDeletedTasks(previousState, currentState);

    // 現在の状態を保存
    console.log("現在の状態を保存")
    savePreviousState(currentState);

  } catch (error) {
    logError(error, 'メイン同期処理');
  }
}




// Notionからタスク一覧を取得
function getNotionTasks() {
  const url = `https://api.notion.com/v1/databases/${CONFIG.NOTION_DATABASE_ID}/query`;
  const response = UrlFetchApp.fetch(url, {
    method: 'POST',
    headers: NOTION_HEADERS,
    payload: JSON.stringify({
      sorts: [
        {
          property: 'DueDate', // 日付プロパティ名
          direction: 'descending' // 昇順にソート（降順の場合は'descending'に変更）
        }
      ],
    })
  });

  console.log("next_cursor", JSON.parse(response.getContentText()).next_cursor)
  return JSON.parse(response.getContentText()).results;
}

// Notionのタスクを更新（カレンダーイベントIDの保存）
function updateNotionTask(taskId, calendarEventId) {
  const url = `https://api.notion.com/v1/pages/${taskId}`;
  return UrlFetchApp.fetch(url, {
    method: 'PATCH',
    headers: NOTION_HEADERS,
    payload: JSON.stringify({
      properties: {
        'Calendar Event ID': {
          rich_text: [{
            text: { content: calendarEventId }
          }]
        }
      }
    })
  });
}

// カレンダーイベントの新規作成
function createCalendarEvent(task, CALENDAR_ID) {
  const calendar = CalendarApp.getCalendarById(CALENDAR_ID);
  const title = task.properties.Name.title[0].plain_text;
  const dueDate = new Date(task.properties.DueDate.date.start);

  if (!dueDate) return

  const event = calendar.createAllDayEvent(
    title,
    dueDate,
    { description: `Notion Task ID: ${task.id}\nURL: ${task.url}` }
  );

  console.log(event)
  return event.getId();
}

// カレンダーイベントの更新
function updateCalendarEvent(eventId, task) {
  const calendar = CalendarApp.getCalendarById(CONFIG.CALENDAR_ID);
  const event = calendar.getEventById(eventId);
  if (!event) return;

  const title = task.properties.Name.title[0].plain_text;
  const dueDate = new Date(task.properties.DueDate.date.start);

  event.setTitle(title);
  event.setAllDayDate(dueDate);
  event.setDescription(`Notion Task ID: ${task.id}\nURL: ${task.url}`);
}

// カレンダーイベントの削除
function deleteCalendarEvent(eventId) {
  const calendar = CalendarApp.getCalendarById(CONFIG.CALENDAR_ID);

  try {
    const event = calendar.getEventById(eventId);
    if (event) {
      event.deleteEvent();
      return true
    }
  } catch (e) {
    console.error("削除されている", e)
    return false

  }

  return false
}

// タスクの現在の状態を取得
function getTaskState(task) {
  return {
    id: task.id,
    title: task.properties.Name.title[0].plain_text,
    dueDate: task.properties.DueDate.date?.start,
    status: task.properties.Status.status ? task.properties.Status.status.name : "None",
    calendarEventId: task.properties['Calendar Event ID']?.rich_text[0]?.text.content
  };
}

// キャッシュから前回の状態を取得
function getPreviousState() {
  const cache = CacheService.getScriptCache();
  const data = cache.get('previousState');

  console.log(JSON.parse(data))
  return data ? JSON.parse(data) : {};
}

// 現在の状態をキャッシュに保存（6時間有効）
function savePreviousState(state) {
  const cache = CacheService.getScriptCache();
  cache.put('previousState', JSON.stringify(state), 21600);
}

// タスクの変更を検出して必要な処理を実行
function processTaskChanges(task, previousState, currentState) {
  const taskId = task.id;
  const prevTask = previousState[taskId];
  const currentTask = currentState[taskId];

  try {
    if (!prevTask && task.properties.DueDate?.date?.start) {
      // 新規タスクの処理
      console.log("新規タスクの処理")
      const calendarEventId = createCalendarEvent(task, CONFIG.CALENDAR_ID);
      updateNotionTask(taskId, calendarEventId);
    } else if (prevTask && prevTask.dueDate) {
      // 既存タスクの処理
      console.log("既存タスクの処理")
      const calendarEventId = prevTask.calendarEventId;
      if (currentTask.status === 'Deleted') {
        // 削除されたタスクの処理
        console.log("削除されたタスクの処理")
        deleteCalendarEvent(calendarEventId);

      } else if (
        prevTask.title !== currentTask.title ||
        prevTask.dueDate !== currentTask.dueDate
      ) {
        // タスクが更新された場合の処理
        console.log("タスクが更新された場合の処理")
        updateCalendarEvent(calendarEventId, task);
      } else if (currentTask.status === 'Done') {
        // ステータスが完了タスクの処理
        console.log("ステータスが完了タスクの処理")
        const reslut = deleteCalendarEvent(calendarEventId);
        console.log("ステータスが完了タスクの処理終了 google カレンダー削除 ",reslut)

        // 削除がない場合終了
        if (!reslut) return

        console.log("別カレンダーに完了を作成")
        // 別カレンダーに完了を作成
        createCalendarEvent(task, CONFIG.DONE_CALENDAR_ID);
        updateNotionTask(taskId, "done");
        console.log("別カレンダーに完了を作成終了")
      }
    }
  } catch (error) {
    logError(error, `タスク処理エラー - TaskID: ${taskId}`);
  }
}

// 削除されたタスクの処理
function processDeletedTasks(previousState, currentState) {
  Object.keys(previousState).forEach(taskId => {
    if (!currentState[taskId]) {
      const calendarEventId = previousState[taskId].calendarEventId;
      if (calendarEventId) {
        try {
          deleteCalendarEvent(calendarEventId);
        } catch (error) {
          logError(error, `削除済みタスクの処理エラー - TaskID: ${taskId}`);
        }
      }
    }
  });
}

// エラーログの記録
function logError(error, context = '') {
  console.error(`同期エラー ${context}:`, error);
  // 必要に応じて追加のエラーハンドリング（Slack通知やメール送信など）


}

// 特定のキャッシュキーを削除する関数
function clearPreviousStateCache() {
  const cache = CacheService.getScriptCache();
  cache.remove('previousState');
  console.log("キャッシュ 'previousState' を削除しました");
}

// 定期実行トリガーの設定
function setUpTrigger() {
  // 既存のトリガーを削除
  ScriptApp.getProjectTriggers().forEach(trigger => {
    ScriptApp.deleteTrigger(trigger);
  });

  // 新しいトリガーを作成（1時間ごとに実行）
  ScriptApp.newTrigger('syncNotionWithCalendar')
    .timeBased()
    .everyHours(1)
    .create();
}
```


## 注意点

1. APIキーの管理
	- 重要な認証情報は適切に管理
	- プロジェクト設定での管理を推奨
2. エラー処理
	- ネットワークエラーへの対応
	- API制限の考慮→ noiton api (１回で100件のページしかとれない)とgasの制限に注意 (稼働時間、fetchのリクエスト回数など)
	- データ整合性の確保→手動編集する場合はnotinのみ編集する
3. パフォーマンス
	- 不要な API 呼び出しの削減
	- キャッシュの活用
	- 適切な実行間隔の設定

## まとめ


このシステムにより、NotionとGoogleカレンダーの連携が自動化され、タスク管理がより効率的になります。実装方法は目的や好みに応じて選択できます。


エラー処理やパフォーマンスの最適化など、実運用時の考慮点も含めて実装することで、より安定した運用が可能になります。


## 参考文献

- [Notion API Documentation](https://developers.notion.com/)
- [Google Calendar API Documentation](https://developers.google.com/calendar)
- [Google Apps Script Documentation](https://developers.google.com/apps-script)
