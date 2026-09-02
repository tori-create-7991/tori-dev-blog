import { siteConfig } from '~/siteConfig'

/**
 * robots.txt を環境で出し分ける。
 *
 * - production: 全許可 + Sitemap 宣言 + 検索/引用系 AI クローラの明示 Allow。
 *   検索用と学習用のクローラは別 User-Agent で、検索用(OAI-SearchBot,
 *   Claude-SearchBot, PerplexityBot 等)を塞ぐと各 AI の回答から消えるため
 *   すべて許可する。
 * - preview: 全面ブロック。本番と同一内容が 2 ドメインで索引されるのを防ぐ。
 *
 * 静的な public/robots.txt では環境で出し分けられないため server route にした。
 * ビルド時に prerender されるので、配信は静的ファイルと同じ。
 */

const PRODUCTION_ROBOTS = (siteUrl: string) => `# ${siteConfig.siteTitle}
# AI 検索・生成AI回答での引用を歓迎する。学習系ボットも許可する。
#
# 注意1: 検索/引用用のクローラ(OAI-SearchBot, Claude-SearchBot, PerplexityBot 等)は
#        学習用ボットとは別 User-Agent で、これらを塞ぐと各 AI の回答から消える。
# 注意2: robots.txt は「最も具体的にマッチする1グループだけ」が適用され、
#        個別グループは User-agent: * の記述を継承しない。
#        そのため Disallow は全グループに同じ内容を書いている。

User-agent: *
Allow: /
# @nuxt/content が生成する内部ダンプ(コンテンツ全文のSQL)。重複コンテンツになるため塞ぐ
Disallow: /__nuxt_content/
# SPA フォールバック用の生成物。実ページではない
Disallow: /404
Disallow: /200

# --- 検索・引用系（絶対にブロックしない）---
User-agent: Googlebot
Allow: /
Disallow: /__nuxt_content/
Disallow: /404
Disallow: /200

User-agent: Bingbot
Allow: /
Disallow: /__nuxt_content/
Disallow: /404
Disallow: /200

User-agent: OAI-SearchBot
Allow: /
Disallow: /__nuxt_content/

User-agent: ChatGPT-User
Allow: /
Disallow: /__nuxt_content/

User-agent: Claude-SearchBot
Allow: /
Disallow: /__nuxt_content/

User-agent: Claude-User
Allow: /
Disallow: /__nuxt_content/

User-agent: PerplexityBot
Allow: /
Disallow: /__nuxt_content/

User-agent: Perplexity-User
Allow: /
Disallow: /__nuxt_content/

User-agent: DuckAssistBot
Allow: /
Disallow: /__nuxt_content/

User-agent: Applebot
Allow: /
Disallow: /__nuxt_content/

# --- 学習系（個人ブランドの認知形成上、許可する）---
User-agent: GPTBot
Allow: /
Disallow: /__nuxt_content/

User-agent: ClaudeBot
Allow: /
Disallow: /__nuxt_content/

User-agent: Google-Extended
Allow: /
Disallow: /__nuxt_content/

User-agent: Applebot-Extended
Allow: /
Disallow: /__nuxt_content/

Sitemap: ${siteUrl}/sitemap.xml
`

const PREVIEW_ROBOTS = `# 検証環境（preview ブランチ）
# 本番 https://tori-dev.com と同一内容のため、検索エンジンには一切開放しない。
# 全ページには meta robots の noindex も出している。

User-agent: *
Disallow: /
`

export default defineEventHandler((event) => {
  const config = useRuntimeConfig()
  const siteUrl = String(config.public.siteUrl).replace(/\/$/, '')
  const isPreview = config.public.siteEnv === 'preview'

  setHeader(event, 'Content-Type', 'text/plain; charset=UTF-8')
  return isPreview ? PREVIEW_ROBOTS : PRODUCTION_ROBOTS(siteUrl)
})
