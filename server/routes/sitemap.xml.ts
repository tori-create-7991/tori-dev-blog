import { sidebarItem, footerItem } from '~/siteConfig'

const escapeXml = (value: string) =>
  value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')

const buildXml = (siteUrl: string, urls: Array<{ path: string; lastmod: string | Date | null }>) => `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls
  .map(
    (u) => `  <url>
    <loc>${escapeXml(siteUrl + u.path)}</loc>${u.lastmod ? `\n    <lastmod>${new Date(u.lastmod).toISOString().split('T')[0]}</lastmod>` : ''}
  </url>`
  )
  .join('\n')}
</urlset>`

export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  const siteUrl = config.public.siteUrl

  setHeader(event, 'Content-Type', 'application/xml; charset=UTF-8')

  // siteConfigのナビ項目(sidebarItem/footerItem)由来の静的パスに、記事詳細ページ用の
  // 動的パスを重複除去しつつ追加する
  const staticPaths = Array.from(
    new Set([...sidebarItem, ...footerItem].map((item) => item.to))
  )

  try {
    const [posts, works, services, feed] = await Promise.all([
      queryCollection(event, 'posts').select('path', 'date').all(),
      queryCollection(event, 'works').select('path', 'date').all(),
      queryCollection(event, 'service').select('path').all(),
      queryCollection(event, 'feed').select('path', 'date').all(),
    ])

    const urls = [
      ...staticPaths.map((path) => ({ path, lastmod: null })),
      ...posts.map((p) => ({ path: p.path, lastmod: p.date })),
      ...works.map((w) => ({ path: w.path, lastmod: w.date })),
      ...services.map((s) => ({ path: s.path, lastmod: null })),
      ...feed.map((f) => ({ path: f.path, lastmod: f.date })),
    ]

    // staticPaths(footerItemの/service/advisory等)と動的パスの重複を除去
    const seen = new Set()
    const dedupedUrls = urls.filter((u) => {
      if (seen.has(u.path)) return false
      seen.add(u.path)
      return true
    })

    return buildXml(siteUrl, dedupedUrls)
  } catch (error) {
    console.error('[sitemap.xml] コンテンツ取得に失敗、静的パスのみで出力します', error)
    return buildXml(
      siteUrl,
      staticPaths.map((path) => ({ path, lastmod: null }))
    )
  }
})
