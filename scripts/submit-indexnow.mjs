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
 *   INDEXNOW_KEY       … public/<key>.txt のキー文字列
 *   NUXT_PUBLIC_SITE_URL … 省略時 https://tori-dev.com
 */

import { readFile } from 'node:fs/promises'
import { existsSync } from 'node:fs'

const ENDPOINT = 'https://api.indexnow.org/indexnow'
const SITEMAP = '.output/public/sitemap.xml'

const dryRun = process.argv.includes('--dry-run')
const siteUrl = (process.env.NUXT_PUBLIC_SITE_URL || 'https://tori-dev.com').replace(/\/$/, '')
const key = process.env.INDEXNOW_KEY

const fail = (msg) => {
  console.error(`[indexnow] ${msg}`)
  process.exit(1)
}

if (!existsSync(SITEMAP)) fail(`${SITEMAP} が無い。先に npm run generate を実行する`)

// preview 環境の URL を誤って送らないための保険
if (!/^https:\/\/tori-dev\.com$/.test(siteUrl)) {
  console.log(`[indexnow] 本番ドメイン以外(${siteUrl})のためスキップ`)
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

if (urls.length === 0) fail('sitemap から URL を抽出できなかった')

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

  const res = await fetch(ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=utf-8' },
    body: JSON.stringify(body),
  })

  // 200 = 受理 / 202 = 受理(キー検証待ち) / 429 = レート制限
  if (res.status === 200 || res.status === 202) {
    sent += chunk.length
    console.log(`[indexnow] ${chunk.length} 件 送信 (HTTP ${res.status})`)
  } else {
    const text = await res.text().catch(() => '')
    // 送信失敗でデプロイ全体を落とさない。通知は補助的な仕組みでしかない
    console.error(`[indexnow] 送信失敗 HTTP ${res.status} ${text.slice(0, 200)}`)
    process.exit(0)
  }
}

console.log(`[indexnow] 完了: ${sent} 件`)
