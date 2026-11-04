<template>
  <div class="search-container">
    <UInput
      v-model="query"
      placeholder="記事を検索..."
      class="w-full"
      icon="i-heroicons-magnifying-glass"
      size="lg"
      :ui="{ base: 'ps-10' }"
    />
    <div v-if="searchResults.length > 0" >
      <ArticleList :articles="searchResults" />
    </div>
    <div v-else-if="query" >
      検索結果が見つかりませんでした
    </div>
    <div v-else >
      <h2 class="text-xl font-bold mb-4">最新の記事</h2>
      <ArticleList :articles="sortedLatestPosts" />
    </div>
  </div>
</template>


<script setup lang="ts">
// タイトルと記事本文を検索している
import Fuse from 'fuse.js'
import { ref, computed } from 'vue'

const query = ref('')
const { data: searchData } = await useAsyncData('search-data', () => queryCollectionSearchSections('posts'))
const { data: latestPosts } = await useAsyncData('latest-posts', () => queryCollection('posts').all())

const fuse = new Fuse(searchData.value || [], {
  keys: ['title', 'content'],
  threshold: 0.3,
})

const searchResults = computed(() => {
  if (!query.value) return []
  const ids = fuse.search(query.value).map(result => {
    console.log(result)
    return result.item.id.split('#')[0]
  })
  console.log(ids)
  if (!latestPosts.value) return []

  console.log(latestPosts.value)
  return latestPosts.value.filter(post => ids.includes(post.path))
})

const sortedLatestPosts = computed(() => {
  if (!latestPosts.value) return []
  return [...latestPosts.value]
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
    .slice(0, 10)
})
</script>

<style scoped>
.search-container {
  /* max-width: 600px; */
  margin: 0 auto;
}

.search-results,
.latest-posts {
  /* max-height: 400px; */
  overflow-y: auto;
}
</style>
