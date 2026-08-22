<template>
    <article class="mx-10">
        <AppBreadcrumb :items="breadcrumbItems" />
        <h1 class="mb-4 font-display text-xl font-bold text-gray-900 dark:text-white">
            <span v-if="currentTag">タグ: {{ currentTag }}</span>
            <span v-else>タグ: すべて</span>
        </h1>

        <div class="flex flex-wrap gap-2 mb-6">
            <span
                v-for="tag in mainStore.tags"
                :key="tag"
                class="px-3 py-1 bg-gray-100 text-gray-800 rounded-full text-sm hover:bg-gray-200 cursor-pointer dark:bg-gray-800"
                @click="moveTag(tag)"
            >
                {{ tag }}
            </span>
        </div>

        <section>
            <ArticleList v-if="storeTagPost && storeTagPost.length > 0" :articles="storeTagPost" />
            <div v-else class="text-center py-8">
                <p class="text-gray-600 dark:text-gray-300">このタグに関連する記事はありません</p>
            </div>
        </section>
    </article>
</template>

<script setup>
const mainStore = useStore()
const route = useRoute()
const { moveTag } = useTag();
const currentTag = ref((route.params.tag))

// storeTagPostをcomputedプロパティとして定義
const storeTagPost = computed(() => mainStore.getTagPost)
// const storeTag = computed(() => mainStore.getTag)

// タグに基づいて記事を取得する関数
const fetchTagPosts = async (tag) => {
    try {
        if (!tag) return []
        console.log("fetchTagPosts", tag)
        console.log("currentTag", currentTag.value)

        return queryCollection('posts')
            .where('tags', 'LIKE', `%${tag}%`)
            .select('path', 'title', 'description', 'date', 'image', 'tags', 'categories')
            .order('id', 'DESC')
            .all()
    } catch (error) {
        console.error('Error fetching tag posts:', error)
        return []
    }
}

// SSG用の初期データ取得
const { data: tagPost, error } = await useAsyncData(route.path, () =>
    fetchTagPosts(currentTag.value)
)

// 初期データの設定
if (error.value) {
    console.error('Error loading initial data:', error.value)
    mainStore.setTagPost([])
} else {
    mainStore.setTagPost(tagPost.value)
}

const postCount = computed(() => storeTagPost.value?.length || 0)

const breadcrumbItems = computed(() => [
    { name: 'ホーム', path: '/' },
    { name: 'ブログ', path: '/posts' },
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
