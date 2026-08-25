import { siteConfig } from '~/siteConfig'

interface PageSeoOptions {
  /** ページ固有のタイトル。省略時は siteConfig.siteTitle のみ */
  title?: string
  /** ページ固有の説明文。省略時はサイト共通の description */
  description?: string
  /** OGP 画像のパス（相対 or 絶対）。省略時は既定 OG 画像 */
  image?: string
  /** 記事系は 'article'、それ以外は 'website' */
  type?: 'website' | 'article'
  /** ISO 8601 の公開日時（type='article' のとき） */
  publishedTime?: string | Date
  /** ISO 8601 の更新日時（type='article' のとき） */
  modifiedTime?: string | Date
  /** 検索結果から外す場合に 'noindex, follow' 等を指定 */
  robots?: string
  /** canonical を明示したい場合のパス。省略時は現在のルートパス */
  path?: string
}

const toIso = (value?: string | Date) => {
  if (!value) return undefined
  const d = value instanceof Date ? value : new Date(value)
  return Number.isNaN(d.getTime()) ? undefined : d.toISOString()
}

/**
 * canonical / OGP / Twitter カードをページ単位でまとめて出力する。
 *
 * - canonical は絶対 URL・末尾スラッシュ無しで統一する（Firebase Hosting の cleanUrls: true に合わせる）。
 *   *.web.app と本番ドメインの重複は Firebase 側でホスト単位のリダイレクトが書けないため、
 *   自己参照 canonical が唯一の正規化手段になる。
 * - og:image は絶対 URL でなければ SNS 側が解決できないため、必ず siteUrl と連結する。
 */
export const usePageSeo = (options: PageSeoOptions = {}) => {
  const route = useRoute()
  const config = useRuntimeConfig()
  const siteUrl = String(config.public.siteUrl).replace(/\/$/, '')
  // 検証環境(preview ブランチ)は本番と同一内容なので、全ページを索引対象から外す。
  // ページ側で robots を明示していてもプレビューの noindex を優先する
  const isPreview = config.public.siteEnv === 'preview'

  const rawPath = options.path ?? route.path
  // cleanUrls: true のため末尾スラッシュは持たせない（ルートのみ '/'）
  const path = rawPath === '/' ? '/' : rawPath.replace(/\/$/, '')
  const canonical = `${siteUrl}${path}`

  const title = options.title
  const description = options.description || siteConfig.description
  const imagePath = options.image || siteConfig.defaultOgImage
  const image = /^https?:\/\//.test(imagePath) ? imagePath : `${siteUrl}${imagePath}`

  useSeoMeta({
    title: () => title,
    description: () => description,
    ogTitle: () => (title ? `${title} | ${siteConfig.siteTitle}` : siteConfig.siteTitle),
    ogDescription: () => description,
    ogType: options.type || 'website',
    ogUrl: canonical,
    ogSiteName: siteConfig.siteTitle,
    ogLocale: siteConfig.locale,
    ogImage: image,
    ogImageAlt: () => title || siteConfig.siteTitle,
    twitterCard: 'summary_large_image',
    twitterTitle: () => (title ? `${title} | ${siteConfig.siteTitle}` : siteConfig.siteTitle),
    twitterDescription: () => description,
    twitterImage: image,
    articlePublishedTime: toIso(options.publishedTime),
    articleModifiedTime: toIso(options.modifiedTime),
    robots: isPreview ? 'noindex, nofollow' : options.robots,
  })

  useHead({
    link: [{ rel: 'canonical', href: canonical }],
  })

  return { canonical, siteUrl, image }
}
