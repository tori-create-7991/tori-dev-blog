// ビルド出力に下書き（content/*/drafts/）が混ざっていないか検査する。
//
// @nuxt/content v3 は全コレクションの SQL ダンプを
// .output/public/__nuxt_content/<collection>/sql_dump.html として静的出力に含める。
// コレクションの source が drafts/ を拾うと、ページから参照されていなくても
// 本番サイトから下書き本文をダウンロードできてしまう（ADR 0004 改訂節）。
//
// 使い方: npm run generate && npm run check-drafts
import { readFileSync, readdirSync, existsSync } from 'node:fs'
import { join } from 'node:path'
import { gunzipSync } from 'node:zlib'

const root = join(process.cwd(), '.output', 'public', '__nuxt_content')

if (!existsSync(root)) {
  console.error(`[check-drafts] ${root} がありません。先に npm run generate を実行してください`)
  process.exit(1)
}

const leaks = []
let checked = 0

for (const collection of readdirSync(root)) {
  const file = join(root, collection, 'sql_dump.html')
  if (!existsSync(file)) continue

  const raw = readFileSync(file, 'utf-8').trim()
  let sql
  try {
    sql = gunzipSync(Buffer.from(raw, 'base64')).toString('utf-8')
  } catch {
    // 圧縮されていない形式で出力された場合はそのまま検査する
    sql = raw
  }
  checked++

  const paths = new Set(sql.match(/'\/[^']*\/drafts\/[^']*'/g) ?? [])
  for (const p of paths) leaks.push(`${collection}: ${p}`)
}

if (checked === 0) {
  console.error('[check-drafts] sql_dump.html が 1 件も見つかりません')
  process.exit(1)
}

if (leaks.length > 0) {
  console.error(`[check-drafts] 下書きがビルド出力に含まれています（${leaks.length} 件）:`)
  for (const l of leaks) console.error(`  ${l}`)
  process.exit(1)
}

console.log(`[check-drafts] OK: ${checked} コレクションに下書きは含まれていません`)
