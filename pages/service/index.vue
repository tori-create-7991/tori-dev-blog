<template>
  <div class="mx-auto max-w-screen-xl px-4 py-10">
    <h1 class="font-display text-2xl font-bold text-gray-900 mb-2 dark:text-white">サービス</h1>
    <p class="mb-8 text-sm text-gray-600 dark:text-gray-300">
      顧問・講師・開発の 3 つの関わり方があります。
    </p>

    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <UCard v-for="item in services" :key="item.path">
        <NuxtLink :to="item.path" class="block">
          <span class="text-xs font-medium text-[#A2A897]">{{ categoryLabel(item.category) }}</span>
          <h2 class="mt-1 font-semibold text-gray-900 dark:text-white">{{ item.title }}</h2>
          <p class="mt-2 text-sm text-gray-600 line-clamp-3 dark:text-gray-300">{{ item.description }}</p>
        </NuxtLink>
      </UCard>
    </div>
  </div>
</template>

<script setup>
import { serviceCategoryLabel } from '~/siteConfig'

const { data: services } = await useAsyncData('service-index', () => {
  return queryCollection('service').all()
})

const categoryLabel = serviceCategoryLabel

usePageSeo({
  title: 'サービス',
  description: '中小企業向けの AI 導入・DX 顧問、プログラミング研修の講師、システム開発の 3 つのサービス。',
})
</script>
