import { siteConfig } from '~/siteConfig'

export const useStructuredData = () => {
  const config = useRuntimeConfig()
  const siteUrl = config.public.siteUrl

  const personJsonLd = () => ({
    '@context': 'https://schema.org',
    '@type': 'Person',
    name: '利根川 諒',
    alternateName: 'Ryo Tonegawa',
    url: siteUrl,
    jobTitle: 'フリーランスエンジニア',
    description: siteConfig.description,
  })

  const articleJsonLd = (post) => ({
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: post?.title,
    description: post?.description,
    datePublished: post?.date,
    image: post?.image ? `${siteUrl}${post.image}` : undefined,
    author: { '@type': 'Person', name: '利根川 諒' },
    url: `${siteUrl}${post?.path}`,
  })

  const creativeWorkJsonLd = (work) => ({
    '@context': 'https://schema.org',
    '@type': 'CreativeWork',
    name: work?.title,
    description: work?.description,
    dateCreated: work?.date,
    creator: { '@type': 'Person', name: '利根川 諒' },
    url: `${siteUrl}${work?.path}`,
  })

  const breadcrumbJsonLd = (items) => ({
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: items.map((item, index) => ({
      '@type': 'ListItem',
      position: index + 1,
      name: item.name,
      item: `${siteUrl}${item.path}`,
    })),
  })

  const injectJsonLd = (data) => {
    useHead({
      script: [
        {
          type: 'application/ld+json',
          innerHTML: JSON.stringify(data),
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
