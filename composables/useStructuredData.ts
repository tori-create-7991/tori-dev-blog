import { siteConfig, authorName } from '~/siteConfig'

interface PostLike {
  title?: string
  description?: string
  date?: string | Date
  image?: string
  path?: string
}

interface WorkLike {
  title?: string
  description?: string
  date?: string | Date
  path?: string
}

interface BreadcrumbItem {
  name?: string
  path: string
}

// JSON-LDをuseHeadのinnerHTMLへ埋め込む際、"</script>"によるscriptタグ早期終了を防ぐ
const escapeForInlineScript = (json: string) => json.replace(/</g, '\\u003c')

export const useStructuredData = () => {
  const config = useRuntimeConfig()
  const siteUrl = config.public.siteUrl

  const personJsonLd = () => ({
    '@context': 'https://schema.org',
    '@type': 'Person',
    name: authorName,
    alternateName: 'Ryo Tonegawa',
    url: siteUrl,
    jobTitle: 'フリーランスエンジニア',
    description: siteConfig.description,
  })

  const articleJsonLd = (post: PostLike) => ({
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: post?.title,
    description: post?.description,
    datePublished: post?.date,
    image: post?.image ? `${siteUrl}${post.image}` : undefined,
    author: { '@type': 'Person', name: authorName },
    url: `${siteUrl}${post?.path}`,
  })

  const creativeWorkJsonLd = (work: WorkLike) => ({
    '@context': 'https://schema.org',
    '@type': 'CreativeWork',
    name: work?.title,
    description: work?.description,
    dateCreated: work?.date,
    creator: { '@type': 'Person', name: authorName },
    url: `${siteUrl}${work?.path}`,
  })

  const breadcrumbJsonLd = (items: BreadcrumbItem[]) => ({
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: items.map((item, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: item.name,
      item: `${siteUrl}${item.path}`,
    })),
  })

  const injectJsonLd = (data: unknown) => {
    useHead({
      script: [
        {
          type: 'application/ld+json',
          innerHTML: escapeForInlineScript(JSON.stringify(data)),
        },
      ],
    })
  }

  return {
    personJsonLd,
    articleJsonLd,
    creativeWorkJsonLd,
    breadcrumbJsonLd,
    injectJsonLd,
  }
}
