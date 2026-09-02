<template>
    <div>
        <h1 class="mb-4 font-display text-xl font-bold text-gray-900 dark:text-white">
            タグ一覧
        </h1>

        <div class="flex flex-wrap gap-2 mb-6">
            <span
                v-for="tag in mainStore.tags"
                :key="tag"
                @click="moveTag(tag)"
                class="px-3 py-1 bg-gray-100 text-gray-800 rounded-full text-sm hover:bg-gray-200 cursor-pointer dark:bg-gray-800"
            >
                {{ tag }}
            </span>
        </div>

        <section>
            <ArticleList :articles="allPosts" />
        </section>
    </div>
</template>

<script setup>
const mainStore = useStore()
const { moveTag } = useTag();

// すべての投稿を取得
const { data: allPosts } = await useAsyncData('all-posts', () =>
    queryCollection('posts')
        .select('path', 'title', 'description', 'date', 'image', 'tags', 'categories')
        .order('date', 'DESC')
        .all()
)

mainStore.setTagPost(allPosts.value)

usePageSeo({
    title: 'タグ一覧',
    description: 'ブログ記事に付けられたタグの一覧。',
})
</script>
