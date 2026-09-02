import {
  siteConfig,
  authorName,
  authorAlternateName,
  authorJobTitle,
  authorArea,
  authorKnowsAbout,
  activeSocialProfiles,
} from '~/siteConfig'

interface PostLike {
  title?: string
  description?: string
  date?: string | Date
  updated?: string | Date
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

const toIso = (value?: string | Date) => {
  if (!value) return undefined
  const d = value instanceof Date ? value : new Date(value)
  return Number.isNaN(d.getTime()) ? undefined : d.toISOString()
}

export const useStructuredData = () => {
  const config = useRuntimeConfig()
  const siteUrl = String(config.public.siteUrl).replace(/\/$/, '')

  // サイト全体で共有するエンティティの @id。
  // ページ個別の JSON-LD からこの @id を参照することで、著者・サイトが同一実体だと明示できる。
  const personId = `${siteUrl}/#person`
  const websiteId = `${siteUrl}/#website`

  const absolute = (path?: string) =>
    path ? (/^https?:\/\//.test(path) ? path : `${siteUrl}${path}`) : undefined

  const personEntity = () => {
    const sameAs = activeSocialProfiles().map((p) => p.url)
    return {
      '@type': 'Person',
      '@id': personId,
      name: authorName,
      alternateName: authorAlternateName,
      url: `${siteUrl}/about`,
      jobTitle: authorJobTitle,
      description: siteConfig.description,
      knowsAbout: authorKnowsAbout,
      address: {
        '@type': 'PostalAddress',
        addressRegion: authorArea,
        addressCountry: 'JP',
      },
      ...(sameAs.length ? { sameAs } : {}),
    }
  }

  const websiteEntity = () => ({
    '@type': 'WebSite',
    '@id': websiteId,
    url: `${siteUrl}/`,
    name: siteConfig.siteTitle,
    description: siteConfig.description,
    inLanguage: siteConfig.lang,
    publisher: { '@id': personId },
  })

  /** サイト全体のエンティティ。app.vue で 1 回だけ出す */
  const siteGraphJsonLd = () => ({
    '@context': 'https://schema.org',
    '@graph': [websiteEntity(), personEntity()],
  })

  /** /about 用。ProfilePage は Google が「ブログの About Me ページ」を明示的に用途として認めている */
  const profilePageJsonLd = () => ({
    '@context': 'https://schema.org',
    '@type': 'ProfilePage',
    '@id': `${siteUrl}/about#profilepage`,
    url: `${siteUrl}/about`,
    name: `${authorName} のプロフィール`,
    isPartOf: { '@id': websiteId },
    mainEntity: { '@id': personId },
  })

  const personJsonLd = () => ({
    '@context': 'https://schema.org',
    ...personEntity(),
  })

  /** 記事は Article ではなく BlogPosting。dateModified / author.url / publisher / mainEntityOfPage を持たせる */
  const articleJsonLd = (post: PostLike) => {
    const url = `${siteUrl}${post?.path || ''}`
    const image = absolute(post?.image)
    return {
      '@context': 'https://schema.org',
      '@type': 'BlogPosting',
      '@id': `${url}#article`,
      headline: post?.title,
      description: post?.description,
      datePublished: toIso(post?.date),
      // 実質更新があれば updated、無ければ公開日を入れる（Google は dateModified を推奨プロパティとしている）
      dateModified: toIso(post?.updated) || toIso(post?.date),
      ...(image ? { image: [image] } : {}),
      author: { '@id': personId },
      publisher: { '@id': personId },
      isPartOf: { '@id': websiteId },
      mainEntityOfPage: { '@type': 'WebPage', '@id': url },
      inLanguage: siteConfig.lang,
      url,
    }
  }

  const creativeWorkJsonLd = (work: WorkLike) => {
    const url = `${siteUrl}${work?.path || ''}`
    return {
      '@context': 'https://schema.org',
      '@type': 'CreativeWork',
      '@id': `${url}#work`,
      name: work?.title,
      description: work?.description,
      dateCreated: toIso(work?.date),
      creator: { '@id': personId },
      isPartOf: { '@id': websiteId },
      inLanguage: siteConfig.lang,
      url,
    }
  }

  /** サービスページ用。リッチリザルトは出ないが、提供内容の意味づけとして CreativeWork より正確 */
  const serviceJsonLd = (service: { title?: string; description?: string; path?: string; price?: string }) => {
    const url = `${siteUrl}${service?.path || ''}`
    return {
      '@context': 'https://schema.org',
      '@type': 'Service',
      '@id': `${url}#service`,
      name: service?.title,
      description: service?.description,
      serviceType: service?.title,
      provider: { '@id': personId },
      areaServed: { '@type': 'Country', name: '日本' },
      inLanguage: siteConfig.lang,
      url,
    }
  }

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
    siteGraphJsonLd,
    profilePageJsonLd,
    personJsonLd,
    articleJsonLd,
    creativeWorkJsonLd,
    serviceJsonLd,
    breadcrumbJsonLd,
    injectJsonLd,
  }
}
