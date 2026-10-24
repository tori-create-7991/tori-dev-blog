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
    // 圧縮されていない形式で出力された場合はそのまま検査する。
    // SQL に見えなければ形式が変わったとみなして失敗させる（base64 のまま検査すると素通りするため）
    if (!/\b(INSERT|CREATE)\b/i.test(raw)) {
      console.error(`[check-drafts] ${file} を展開できません（ダンプ形式が変わった可能性）`)
      process.exit(1)
    }
    sql = raw
  }
  checked++

  // path('/posts/drafts/x', drafts/index.md なら '/posts/drafts')・id('content/posts/drafts/x.md')・
  // stem('posts/drafts/x')、トップレベルの drafts/ も拾う。id 列は frontmatter の path: で
  // 上書きできないので、path を書き換えた下書きも id で検出できる。
  // 空白を含まない引用文字列に限るので、本文中で drafts/ に言及しているだけの記事は誤検知しない
  const paths = new Set(sql.match(/'(?:[^'\s]*\/)?drafts(?:\/[^'\s]*)?'/g) ?? [])
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
