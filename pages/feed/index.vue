<template>
  <div class="mx-auto max-w-screen-md px-4 py-10">
    <h1 class="font-display text-2xl font-bold text-gray-900 mb-8 dark:text-white">Feed</h1>

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

const { formatDate } = useFormatDate()

const { data: items } = await useAsyncData('feed-index', () => {
  return queryCollection('feed').order('date', 'DESC').all()
})

useHead({
  title: 'Feed | tori-dev',
  meta: [
    { name: 'description', content: 'X / Bluesky / Instagramの投稿一覧。' },
  ],
})
</script>
