export default defineEventHandler(async (event) => {
  const config = useRuntimeConfig()
  const siteUrl = config.public.siteUrl

  const staticPaths = ['/', '/works', '/posts', '/advisory', '/sidecontent/about']

  const [posts, works] = await Promise.all([
    queryCollection(event, 'posts').select('path', 'date').all(),
    queryCollection(event, 'works').select('path', 'date').all(),
  ])

  const urls = [
    ...staticPaths.map((path) => ({ path, lastmod: null })),
    ...posts.map((p) => ({ path: p.path, lastmod: p.date })),
    ...works.map((w) => ({ path: w.path, lastmod: w.date })),
  ]

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls
  .map(
    (u) => `  <url>
    <loc>${siteUrl}${u.path}</loc>${u.lastmod ? `\n    <lastmod>${new Date(u.lastmod).toISOString().split('T')[0]}</lastmod>` : ''}
  </url>`
  )
  .join('\n')}
</urlset>`

  setHeader(event, 'Content-Type', 'application/xml; charset=UTF-8')
  return xml
})
