<template>
  <div class="mx-auto max-w-screen-md px-4 py-10">
    <h1 class="font-display text-2xl font-bold text-gray-900 mb-2 dark:text-white">つぶやき</h1>
    <p class="mb-8 text-sm text-gray-600 dark:text-gray-300">
      X / Bluesky に書いた短文をここにまとめています。
    </p>

    <div v-if="items?.length" class="space-y-4">
      <UCard v-for="item in items" :key="item.path">
        <p class="text-sm text-gray-500 dark:text-gray-400">{{ formatDate(item.date) }}</p>
        <div class="prose max-w-none mt-2">
          <ContentRenderer :value="item" />
        </div>
        <a v-if="item.sourceUrl" :href="item.sourceUrl" target="_blank" class="mt-2 inline-block text-sm text-[#A2A897] hover:underline">
          元投稿を見る
        </a>
      </UCard>
    </div>
    <p v-else class="text-gray-500 dark:text-gray-400">
      準備中です。X / Bluesky / Instagramの投稿をここに転載予定です。
    </p>
  </div>
</template>

<script setup>
import { useFormatDate } from '~/composables/useFormatDate'
import { feedPublished } from '~/siteConfig'

const { formatDate } = useFormatDate()

const { data: items } = await useAsyncData('feed-index', () => {
  return queryCollection('feed').order('date', 'DESC').all()
})

// 0 件のうちは中身が無いページになるため noindex。件数が増えたら feedPublished を true にする
usePageSeo({
  title: 'つぶやき',
  description: 'X / Bluesky / Instagram に書いた短文の一覧。',
  robots: !feedPublished || !items.value?.length ? 'noindex, follow' : undefined,
})
</script>
