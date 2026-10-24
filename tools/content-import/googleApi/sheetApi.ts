import { google } from 'googleapis'
// import { spreadsheetIdList } from './Config'
const testSpreadsheetId=  ""

export const getRange = async (
  auth: any,
  spreadsheetId: string,
  range: string
) => {
  const sheets = google.sheets('v4')
  const values = await sheets.spreadsheets.values.get({
    auth,
    spreadsheetId: spreadsheetId,
    range: range
  })

  console.log(values.data.values)
}

export const sheetAppend = async (auth: any) => {
  const firstRowNumber = 1
  const lastRwoNumber = 2
  const cloumnNumber = 2
  const sheets = google.sheets('v4')
  const result = await sheets.spreadsheets.values.append({
    auth,
    spreadsheetId: testSpreadsheetId, // 書き込みたいスプレッドシートのID
    range: `R${firstRowNumber}C1:R${lastRwoNumber}C${cloumnNumber}`, //書き込み先のシート名やセル範囲
    valueInputOption: 'RAW',
    insertDataOption: 'OVERWRITE',
    requestBody: {
      majorDimension: null,
      range: null,
      values: [
        [
          'testValues1',
          'testValues1'
          // snapshotData[0][0] //ドキュメントID
          // snapshotData[0][1] //ドキュメントの任意の属性を必要なだけ入れる
        ],
        ['testValues2', 'testValues2']
      ]
    }
  })

  console.log('結果' + result.data.updates?.updatedRange)
}

export const sheetBatchUpdate = async (
  auth: any,
  spreadsheetId: string,
  values: any[][]
) => {
  const firstRowNumber = 2
  const lastRwoNumber = values.length + (firstRowNumber - 1)
  const cloumnNumber = values[0].length
  const sheets = google.sheets('v4')

  // Do the magic
  const res = await sheets.spreadsheets.values.batchUpdate({
    auth,
    // The ID of the spreadsheet to update.
    spreadsheetId: spreadsheetId,

    // Request body metadata
    requestBody: {
      // request body parameters

      data: [
        {
          majorDimension: null,
          range: `R${firstRowNumber}C1:R${lastRwoNumber}C${cloumnNumber}`, //書き込み先のシート名やセル範囲
          // values: [
          //   [
          //     `testValues${date.getSeconds()}`,
          //     `testValues${date.getSeconds()}`
          //   ],
          //   [`testValues${date.getSeconds()}`, `testValues${date.getSeconds()}`]
          // ]
          values: values
        }
      ],
      valueInputOption: 'RAW'
    }
  })

  console.log(res.data)

  // Example response
  // {
  //   "responses": [],
  //   "spreadsheetId": "my_spreadsheetId",
  //   "totalUpdatedCells": 0,
  //   "totalUpdatedColumns": 0,
  //   "totalUpdatedRows": 0,
  //   "totalUpdatedSheets": 0
  // }
}
