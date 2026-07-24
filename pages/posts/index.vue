<template>
  <div class="mx-auto max-w-screen-xl px-4 py-10">
    <h1 class="font-display text-2xl font-bold text-gray-900 mb-8">Blog</h1>
    <ArticleList :articles="posts" />
  </div>
</template>

<script setup>
const { data: posts } = await useAsyncData('posts-index', () => {
  return queryCollection('posts').order('date', 'DESC').all()
})

useHead({
  title: 'Blog | tori-dev',
  meta: [
    { name: 'description', content: '技術記事一覧。' },
  ],
})
</script>
