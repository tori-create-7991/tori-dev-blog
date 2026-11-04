<template>
    <article class="mx-10">
        <AppBreadcrumb :items="breadcrumbItems" />
        <h1 class="mb-4 font-display text-xl font-bold text-gray-900 dark:text-white">
            <span v-if="currentTag">タグ: {{ currentTag }}</span>
            <span v-else>タグ: すべて</span>
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
            <ArticleList v-if="tagPost && tagPost.length > 0" :articles="tagPost" />
            <div v-else class="text-center py-8">
                <p class="text-gray-600 dark:text-gray-300">このタグに関連する記事はありません</p>
            </div>
        </section>
    </article>
</template>

<script setup>
const route = useRoute()
const { tags } = await usePostTaxonomy()
const currentTag = computed(() => route.params.tag)

// タグに基づいて記事を取得する
const { data: tagPost } = await useAsyncData(route.path, () =>
    queryCollection('posts')
        .select('path', 'title', 'description', 'date', 'image', 'tags', 'categories')
        .order('id', 'DESC')
        .all()
        // SQL の LIKE だと部分一致・大文字小文字無視になり、記号を含む名前は弾かれるので、ここで完全一致で絞る
        .then(posts => posts.filter(post => post.tags?.includes(currentTag.value)))
)

const postCount = computed(() => tagPost.value?.length || 0)

const breadcrumbItems = computed(() => [
    { name: 'Home', path: '/' },
    { name: 'Blog', path: '/posts' },
    { name: `タグ: ${currentTag.value}`, path: route.path },
])

// 記事が 1 本以下のタグページは内容が薄く、全体の品質評価にマイナスになるため
// インデックスさせない。リンクは辿らせる(follow)。
usePageSeo({
    title: `${currentTag.value} の記事`,
    description: `「${currentTag.value}」タグが付いた記事の一覧（${postCount.value}件）。`,
    robots: postCount.value <= 1 ? 'noindex, follow' : undefined,
})
</script>

<style></style>
