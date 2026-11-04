<template>
  <article class="mx-10">
    <AppBreadcrumb :items="breadcrumbItems" />
    <h1 class="mb-4 font-display text-xl font-bold text-gray-900 dark:text-white">
      <span v-if="currentCategory">カテゴリー: {{ currentCategory }}</span>
      <span v-else>カテゴリー: すべて</span>
    </h1>

    <div class="flex flex-wrap gap-2 mb-6">
      <NuxtLink
        v-for="category in categories"
        :key="category"
        :to="categoryPath(category)"
        class="px-3 py-1 bg-gray-100 text-gray-800 rounded-full text-sm hover:bg-gray-200 cursor-pointer dark:bg-gray-800"
      >
        {{ category }}
      </NuxtLink>
    </div>

    <section>
      <ArticleList
        v-if="categoryPost && categoryPost.length > 0"
        :articles="categoryPost"
      />
      <div v-else class="text-center py-8">
        <p class="text-gray-600 dark:text-gray-300">このカテゴリーに関連する記事はありません</p>
      </div>
    </section>
  </article>
</template>

<script setup>
const route = useRoute()
const { categories } = await usePostTaxonomy()
const currentCategory = ref(route.params.category)

// カテゴリーに基づいて記事を取得する
const { data: categoryPost } = await useAsyncData(route.path, () =>
    queryCollection('posts')
        .select('path', 'title', 'description', 'date', 'image', 'tags', 'categories')
        .order('id', 'DESC')
        .all()
        // SQL の LIKE だと部分一致・大文字小文字無視になり、記号を含む名前は弾かれるので、ここで完全一致で絞る
        .then(posts => posts.filter(post => post.categories?.includes(currentCategory.value)))
)

const postCount = computed(() => categoryPost.value?.length || 0)

const breadcrumbItems = computed(() => [
    { name: 'Home', path: '/' },
    { name: 'Blog', path: '/posts' },
    { name: `カテゴリー: ${currentCategory.value}`, path: route.path },
])

// 記事 1 本以下のカテゴリページは noindex, follow（薄いページをインデックスさせない）
usePageSeo({
    title: `${currentCategory.value} の記事`,
    description: `カテゴリー「${currentCategory.value}」の記事一覧（${postCount.value}件）。`,
    robots: postCount.value <= 1 ? 'noindex, follow' : undefined,
})

</script>

<style>
.search-from {
  color: #000;
  background-color: cornsilk;
}

.content-meta {
  display: flex;
  /* justify-content: space-around; */
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
