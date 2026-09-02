<template>
  <div class="mx-auto max-w-screen-md px-4 py-20 text-center">
    <p class="font-display text-5xl font-bold text-[#A2A897]">{{ error?.statusCode || 500 }}</p>
    <h1 class="mt-4 font-display text-2xl font-bold text-gray-900 dark:text-white">
      {{ title }}
    </h1>
    <p class="mt-3 text-sm text-gray-600 dark:text-gray-300">
      {{ message }}
    </p>
    <div class="mt-8 flex flex-wrap justify-center gap-4 text-sm">
      <NuxtLink to="/" class="text-[#A2A897] hover:underline">ホームへ戻る</NuxtLink>
      <NuxtLink to="/posts" class="text-[#A2A897] hover:underline">ブログ一覧</NuxtLink>
      <NuxtLink to="/contact" class="text-[#A2A897] hover:underline">お問い合わせ</NuxtLink>
    </div>
  </div>
</template>

<script setup>
import { siteConfig } from '~/siteConfig'

const props = defineProps({
  error: {
    type: Object,
    default: null,
  },
})

const isNotFound = computed(() => props.error?.statusCode === 404)
const title = computed(() => (isNotFound.value ? 'ページが見つかりません' : 'エラーが発生しました'))
const message = computed(() =>
  isNotFound.value
    ? 'URL が変更されたか、削除された可能性があります。下のリンクから目的のページを探してください。'
    : '時間をおいて再度アクセスしてください。'
)

// エラーページは lang / title が無いと品質シグナル上マイナスになるため明示する。
// 検索結果には出さない
useHead({
  htmlAttrs: { lang: siteConfig.lang },
  title: () => title.value,
  meta: [{ name: 'robots', content: 'noindex' }],
})
</script>
