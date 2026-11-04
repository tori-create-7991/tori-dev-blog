<template>
    <div>
        <h1 class="mb-4 font-display text-xl font-bold text-gray-900 dark:text-white">
            タグ一覧
        </h1>

        <div class="flex flex-wrap gap-2 mb-6">
            <NuxtLink
                v-for="tag in tags"
                :key="tag"
                :to="tagPath(tag)"
                class="px-3 py-1 bg-gray-100 text-gray-800 rounded-full text-sm hover:bg-gray-200 cursor-pointer dark:bg-gray-800 dark:text-gray-200"
            >
                {{ tag }}
            </NuxtLink>
        </div>

        <section>
            <ArticleList :articles="allPosts" />
        </section>
    </div>
</template>

<script setup>
const { tags } = await usePostTaxonomy()

// すべての投稿を取得
const { data: allPosts } = await useAsyncData('all-posts', () =>
    queryCollection('posts')
        .select('path', 'title', 'description', 'date', 'image', 'tags', 'categories')
        .order('date', 'DESC')
        .all()
)

usePageSeo({
    title: 'タグ一覧',
    description: 'ブログ記事に付けられたタグの一覧。',
})
</script>
