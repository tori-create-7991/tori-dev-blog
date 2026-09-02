<template>
  <UApp>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </UApp>
</template>

<script setup>
import { siteConfig } from '~/siteConfig'

const config = useRuntimeConfig()
const siteUrl = String(config.public.siteUrl).replace(/\/$/, '')

useHead({
  htmlAttrs: {
    lang: siteConfig.lang,
  },
  // 各ページは素のタイトルだけを渡し、サイト名の連結はここで行う。
  // トップのようにページ固有タイトルが無い場合はサイト名だけにする（"tori-dev | tori-dev" を防ぐ）
  titleTemplate: (title) =>
    !title || title === siteConfig.siteTitle ? siteConfig.siteTitle : `${title} | ${siteConfig.siteTitle}`,
  meta: [
    { charset: 'utf-8' },
    { name: 'viewport', content: 'width=device-width, initial-scale=1' },
  ],
  link: [
    // RSS の発見用。フィードリーダー・一部のエージェントがこの alternate を辿る
    {
      rel: 'alternate',
      type: 'application/rss+xml',
      title: `${siteConfig.siteTitle} のブログ`,
      href: `${siteUrl}/rss.xml`,
    },
  ],
})

// サイト全体で共通のメタ。ページ側で usePageSeo を呼べば上書きされる
useSeoMeta({
  description: siteConfig.description,
  ogSiteName: siteConfig.siteTitle,
  ogLocale: siteConfig.locale,
  ogType: 'website',
  twitterCard: 'summary_large_image',
})

// サイト全体のエンティティ（WebSite + Person）。ページ個別の JSON-LD とは @id で繋がる
const { siteGraphJsonLd, injectJsonLd } = useStructuredData()
injectJsonLd(siteGraphJsonLd())
</script>
