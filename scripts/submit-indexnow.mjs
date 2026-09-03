#!/usr/bin/env node
/**
 * ビルド済み sitemap.xml の URL を IndexNow に一括送信する。
 *
 * IndexNow は Bing / Yandex / Naver / Seznam / Yep が参加する更新通知の仕組みで、
 * 1つのエンドポイントに送れば参加エンジン全体に共有される。
 * Google は非対応なので、Google 向けには sitemap と通常のクロールに任せる。
 *
 * 本番(main)のデプロイ時だけ実行する。preview は noindex なので送らない。
 *
 * 使い方:
 *   node scripts/submit-indexnow.mjs                 # .output/public/sitemap.xml から送信
 *   node scripts/submit-indexnow.mjs --dry-run       # 送信せず対象だけ表示
 *
 * 必要な環境変数:
 *   INDEXNOW_KEY         … public/<key>.txt のキー文字列。IndexNow の仕様上
 *                          公開前提の値なので秘匿対象ではない（Secrets 管理は形式的）
 *   NUXT_PUBLIC_SITE_ENV … production 以外はスキップ（preview 誤送信の保険）
 *   NUXT_PUBLIC_SITE_URL … 省略時 https://tori-dev.com
 *
 * 送信失敗・ネットワーク例外・sitemap 不在のいずれでもデプロイを落とさない。
 * 通知は補助的な仕組みで、失敗は Actions の warning として残すだけにする。
 */

import { readFile } from 'node:fs/promises'
import { existsSync } from 'node:fs'

const ENDPOINT = 'https://api.indexnow.org/indexnow'
const SITEMAP = '.output/public/sitemap.xml'
// api.indexnow.org が無応答のとき CI の死活確認を長時間ブロックしないための上限
const TIMEOUT_MS = 20_000

const dryRun = process.argv.includes('--dry-run')
const siteUrl = (process.env.NUXT_PUBLIC_SITE_URL || 'https://tori-dev.com').replace(/\/$/, '')
const key = process.env.INDEXNOW_KEY

// デプロイを巻き込まないため、異常系は warning annotation を出して正常終了する
const warn = (msg) => {
  console.error(`[indexnow] ${msg}`)
  console.log(`::warning title=IndexNow::${msg}`)
  process.exit(0)
}

if (!existsSync(SITEMAP)) warn(`${SITEMAP} が無い。先に npm run generate を実行する`)

// preview 環境の URL を誤って送らないための保険。
// 本番ドメインをここにハードコードすると CI の vars.CUSTOM_DOMAIN と二重管理になり、
// ドメイン変更時に通知だけが黙って止まる。CI と同じ site_env を見る
if (process.env.NUXT_PUBLIC_SITE_ENV !== 'production') {
  console.log(`[indexnow] site_env=${process.env.NUXT_PUBLIC_SITE_ENV || '(未設定)'} のためスキップ`)
  process.exit(0)
}

if (!key && !dryRun) {
  console.log('[indexnow] INDEXNOW_KEY が未設定のためスキップ')
  process.exit(0)
}

const xml = await readFile(SITEMAP, 'utf-8')
const urls = [...xml.matchAll(/<loc>([^<]+)<\/loc>/g)]
  .map((m) => m[1].trim())
  .filter((u) => u.startsWith(siteUrl))

if (urls.length === 0) warn('sitemap から URL を抽出できなかった')

console.log(`[indexnow] ${urls.length} 件を送信対象にした`)

if (dryRun) {
  urls.slice(0, 10).forEach((u) => console.log(`  ${u}`))
  if (urls.length > 10) console.log(`  ... 他 ${urls.length - 10} 件`)
  process.exit(0)
}

// 1リクエストあたり最大 10,000 URL。この規模では分割不要だが念のため区切る
const CHUNK = 1000
let sent = 0
for (let i = 0; i < urls.length; i += CHUNK) {
  const chunk = urls.slice(i, i + CHUNK)
  const body = {
    host: new URL(siteUrl).host,
    key,
    keyLocation: `${siteUrl}/${key}.txt`,
    urlList: chunk,
  }

  // DNS 失敗・TLS エラー・無応答は fetch 自体が reject する。
  // 捕捉しないと未処理 rejection で非ゼロ終了になり、CI の後続ステップを止める
  let res
  try {
    res = await fetch(ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=utf-8' },
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    })
  } catch (error) {
    warn(`送信で例外: ${error?.name || ''} ${error?.message || error}`)
  }

  // 200 = 受理 / 202 = 受理(キー検証待ち) / 429 = レート制限
  if (res.status === 200 || res.status === 202) {
    sent += chunk.length
    console.log(`[indexnow] ${chunk.length} 件 送信 (HTTP ${res.status})`)
  } else {
    const text = await res.text().catch(() => '')
    warn(`送信失敗 HTTP ${res.status} ${text.slice(0, 200)}`)
  }
}

console.log(`[indexnow] 完了: ${sent} 件`)
