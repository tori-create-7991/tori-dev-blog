<template>
  <article class="mx-10">
    <div class="mb-4 text-lg font-semibold">
      <span v-if="currentCategory">
        カテゴリー: {{ currentCategory }}
      </span>
      <span v-else>カテゴリー: すべて</span>
    </div>

    <div class="flex flex-wrap gap-2 mb-6">
      <span
        v-for="category in mainStore.categories"
        :key="category"
        class="px-3 py-1 bg-gray-100 text-gray-800 rounded-full text-sm hover:bg-gray-200 cursor-pointer dark:bg-gray-800"
        @click="moveCategory(category)"
      >
        {{ category }}
      </span>
    </div>

    <section>
      <ArticleList
        v-if="storeCategoryPost && storeCategoryPost.length > 0"
        :articles="storeCategoryPost"
      />
      <div v-else class="text-center py-8">
        <p class="text-gray-600 dark:text-gray-300">このカテゴリーに関連する記事はありません</p>
      </div>
    </section>
  </article>
</template>

<script setup>
const mainStore = useStore()
const route = useRoute()
const { moveCategory } = useCategory();
const currentCategory = ref((route.params.category))

// storeCategoryPostをcomputedプロパティとして定義
const storeCategoryPost = computed(() => mainStore.getCategoryPost)

// カテゴリーに基づいて記事を取得する関数
const fetchCategoryPosts = async (category) => {
    try {
        if (!category) return []
        console.log("fetchCategoryPosts", category)
        console.log("currentCategory", currentCategory.value)

        return queryCollection('posts')
            .where('categories', 'LIKE', `%${category}%`)
            .order('id', 'DESC')
            .all()
    } catch (error) {
        console.error('Error fetching category posts:', error)
        return []
    }
}

// SSG用の初期データ取得
const { data: categoryPost, error } = await useAsyncData(route.path, () =>
    fetchCategoryPosts(currentCategory.value)
)

// 初期データの設定
if (error.value) {
    console.error('Error loading initial data:', error.value)
    mainStore.setCategoryPost([])
} else {
    mainStore.setCategoryPost(categoryPost.value)
}

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
