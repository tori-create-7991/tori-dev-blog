<template>
  <div class="mx-auto max-w-screen-xl px-4 py-10">
    <h1 class="font-display text-2xl font-bold text-gray-900 mb-2 dark:text-white">ブログ</h1>
    <p class="mb-8 text-sm text-gray-600 dark:text-gray-300">
      AI 導入・DX 支援や開発の現場で実際にやったことと、その結果を記録しています。
    </p>
    <ContentSearch />
  </div>
</template>

<script setup>
import ContentSearch from '~/components/ContentSearch.vue'

usePageSeo({
  title: 'ブログ',
  description: 'AI 導入・DX 支援、ERP 開発、講師業の現場で実際にやったことと結果を記録した技術記事の一覧。',
})
</script>
