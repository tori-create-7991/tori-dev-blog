import { siteConfig, authorName } from '~/siteConfig'

const escapeXml = (value: string) =>
  value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')

const rfc822 = (value: string | Date | null | undefined) => {
  if (!value) return undefined
  const d = value instanceof Date ? value : new Date(value)
  return Number.isNaN(d.getTime()) ? undefined : d.toUTCString()
}

/**
 * ブログ記事の RSS 2.0 フィード。
 * 検索順位には効かないが、購読・他サービスへの配信・一部エージェントの更新検知に使われる。
 * sitemap.xml.ts と同じく server route + prerender で静的化する。
 */
export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  const siteUrl = String(config.public.siteUrl).replace(/\/$/, '')

  setHeader(event, 'Content-Type', 'application/rss+xml; charset=UTF-8')

  let posts: Array<{ path: string; title?: string; description?: string; date?: string | Date; updated?: string | Date }> = []
  try {
    posts = await queryCollection(event, 'posts')
      .select('path', 'title', 'description', 'date', 'updated')
      .order('date', 'DESC')
      .limit(50)
      .all()
  } catch (error) {
    console.error('[rss.xml] コンテンツ取得に失敗、空のフィードを返します', error)
  }

  const items = posts
    .map((post) => {
      const url = `${siteUrl}${post.path}`
      const pubDate = rfc822(post.updated || post.date)
      return `    <item>
      <title>${escapeXml(post.title || '')}</title>
      <link>${escapeXml(url)}</link>
      <guid isPermaLink="true">${escapeXml(url)}</guid>
      <description>${escapeXml(post.description || '')}</description>${pubDate ? `\n      <pubDate>${pubDate}</pubDate>` : ''}
      <dc:creator>${escapeXml(authorName)}</dc:creator>
    </item>`
    })
    .join('\n')

  const lastBuildDate = rfc822(posts[0]?.updated || posts[0]?.date) || new Date(0).toUTCString()

  return `<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>${escapeXml(siteConfig.siteTitle)} のブログ</title>
    <link>${escapeXml(`${siteUrl}/posts`)}</link>
    <description>${escapeXml(siteConfig.description)}</description>
    <language>${escapeXml(siteConfig.lang)}</language>
    <lastBuildDate>${lastBuildDate}</lastBuildDate>
    <atom:link href="${escapeXml(`${siteUrl}/rss.xml`)}" rel="self" type="application/rss+xml" />
${items}
  </channel>
</rss>`
})
