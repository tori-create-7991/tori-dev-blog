<template>
  <div>
    <h1 class="mb-4 font-display text-xl font-bold text-gray-900 dark:text-white">
      カテゴリー一覧
    </h1>

    <div class="flex flex-wrap gap-2 mb-6">
      <NuxtLink
        v-for="category in categories"
        :key="category"
        :to="categoryPath(category)"
        class="px-3 py-1 bg-gray-100 text-gray-800 rounded-full text-sm hover:bg-gray-200 cursor-pointer dark:bg-gray-800 dark:text-gray-200"
      >
        {{ category }}
      </NuxtLink>
    </div>
    <section>
      <ArticleList
        :articles="allPosts"
      />
    </section>
  </div>
</template>

<script setup>
const { categories } = await usePostTaxonomy()

const { data: allPosts } = await useAsyncData('all-posts', () =>
    queryCollection('posts')
        .select('path', 'title', 'description', 'date', 'image', 'tags', 'categories')
        .order('date', 'DESC')
        .all()
)

usePageSeo({
  title: 'カテゴリー一覧',
  description: 'ブログ記事のカテゴリー一覧。',
})
</script>

<style>
.search-from {
  color: #000;
  background-color: cornsilk;
}

.content-meta {
  display: flex;
}

.card-tags {
  margin-left: 5%;
}

.card-created-day {
  margin-top: 3%;
  margin-left: 5%;
}

.card-img {
  max-height: 200px;
  width: 100%;
}
</style>
