<template>
    <article class="mx-10">
        <div class="mb-4 text-lg font-semibold">
            <span v-if="currentTag">タグ: {{ currentTag }}</span>
            <span v-else>タグ: すべて</span>
        </div>

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



</script>

<style></style>
