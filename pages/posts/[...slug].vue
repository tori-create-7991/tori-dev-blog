<template>
    <div class="flex flex-col lg:flex-row">
        <!-- 目次トグルボタン -->
        <div v-if="!isTocVisible">
            <button
                @click="isTocVisible = !isTocVisible"
                class="fixed right-4 top-20 bg-white text-gray-600 px-3 py-1.5 rounded-md shadow-sm border border-gray-200 hover:bg-gray-50 transition-colors duration-200 dark:hover:bg-gray-800 dark:border-gray-700 dark:text-gray-300 dark:bg-[#121212]"
            >
                <div class="flex items-center">
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-5 w-5 mr-1"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M4 6h16M4 12h16M4 18h16"
                        />
                    </svg>
                    {{ '目次' }}
                </div>
            </button>
        </div>
        <!-- メインコンテンツ -->
        <article
            :class="[
                'mx-0 lg:mx-auto lg:max-w-screen-md lg:w-full px-4 py-8',
                isTocVisible ? 'lg:pr-72' : ''
            ]"
        >
            <div>
                <AppBreadcrumb :items="breadcrumbItems" />
                <h1 class="font-display text-2xl sm:text-3xl font-bold text-gray-900 dark:text-white">
                    {{ post?.title }}
                </h1>
                <NuxtImg
                    v-if="post?.image"
                    :src="post.image"
                    class="w-full h-72 object-contain mt-6 rounded-lg bg-gray-50 dark:bg-gray-800"
                    format="webp"
                    width="768"
                    height="288"
                    sizes="sm:100vw md:768px"
                    :placeholder="[50, 25, 75, 5]"
                    :alt="post.title"
                />
                <!-- メタ行: 公開日 / 更新日 / 著者バイライン。
                     Google は「著者情報へ導くバイライン」を明示的に求めており、
                     日付は ISO 8601 を datetime 属性で持たせる -->
                <div class="flex flex-wrap items-center gap-x-4 gap-y-2 mt-4 text-sm text-gray-500 dark:text-gray-400">
                    <time :datetime="isoDate(post?.date)">公開 {{ formatDate(post?.date) }}</time>
                    <time v-if="post?.updated" :datetime="isoDate(post?.updated)">
                        更新 {{ formatDate(post?.updated) }}
                    </time>
                    <span>
                        文
                        <NuxtLink to="/about" class="text-[#A2A897] hover:underline">{{ authorName }}</NuxtLink>
                    </span>
                </div>
                <div class="flex flex-wrap items-center gap-3 mt-3 text-sm">
                    <UBadge
                        v-for="tag in post?.tags"
                        :key="tag"
                        color="neutral"
                        variant="subtle"
                        class="cursor-pointer"
                        @click="moveTag(tag)"
                    >
                        {{ tag }}
                    </UBadge>
                </div>
                <div class="prose max-w-none mt-8">
                    <ContentRenderer :value="post" />
                </div>
                <div v-if="post?.advertisements" class="mt-12">
                    <p class="text-gray-600 dark:text-gray-300">広告を表示しています</p>
                    <div
                        v-for="n in post.advertisements"
                        :key="n"
                        v-html="n"
                        class="mt-4"
                    ></div>
                </div>
                <!-- 著者ボックス: E-E-A-T の「誰が書いたか」を記事末尾でも明示する -->
                <aside class="mt-16 rounded-lg border border-gray-200 p-5 dark:border-[#333333] dark:bg-[#1a1a1a]">
                    <p class="text-xs uppercase tracking-wider text-gray-500 dark:text-gray-400">この記事を書いた人</p>
                    <p class="mt-2 font-display text-lg font-semibold text-gray-900 dark:text-white">{{ authorName }}</p>
                    <p class="mt-1 text-sm text-gray-600 dark:text-gray-300">{{ authorJobTitle }}（{{ authorArea }}）</p>
                    <div class="mt-4 flex flex-wrap gap-4 text-sm">
                        <NuxtLink to="/about" class="text-[#A2A897] hover:underline">プロフィール</NuxtLink>
                        <NuxtLink to="/contact" class="text-[#A2A897] hover:underline">ご相談・お問い合わせ</NuxtLink>
                    </div>
                </aside>

                <div v-if="categoryPost?.length" class="mt-16 mb-16">
                    <h2 class="font-display text-lg font-semibold text-gray-900 mb-4 dark:text-white">関連記事</h2>
                    <ArticleList :articles="categoryPost" />
                </div>
            </div>
        </article>

        <!-- サイドバー -->
        <div
            :class="[
                'w-full lg:w-64 fixed lg:right-0 top-0 h-screen overflow-y-auto bg-white dark:bg-[#121212] p-4 transition-all duration-300',
                isTocVisible ? 'translate-x-0' : 'translate-x-full',
                'mt-20', // ヘッダーの高さ分のマージン
            ]"
        >
            <div class="flex justify-between items-center mb-4">
                <h2 class="text-lg font-bold">目次</h2>
                <button
                    @click="isTocVisible = false"
                    class="text-gray-500 hover:text-gray-700 dark:text-gray-400"
                    aria-label="Close table of contents"
                >
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-6 w-6"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M6 18L18 6M6 6l12 12"
                        />
                    </svg>
                </button>
            </div>
            <ul class="space-y-2">
                <template v-for="link in post?.body?.toc?.links" :key="link.id">
                    <li :class="`pl-${(link.depth - 1) * 2}`">
                        <a
                            :href="`#${link.id}`"
                            class="text-[#A2A897] hover:text-[#8b9179] block py-1"
                            @click.prevent="scrollToHeading(link.id)"
                        >
                            {{ link.text }}
                        </a>
                    </li>
                    <template v-if="link.children">
                        <li
                            v-for="child in link.children"
                            :key="child.id"
                            :class="`pl-${(child.depth - 1) * 2}`"
                        >
                            <a
                                :href="`#${child.id}`"
                                class="text-[#A2A897] hover:text-[#8b9179] block py-1"
                                @click.prevent="scrollToHeading(child.id)"
                            >
                                {{ child.text }}
                            </a>
                        </li>
                    </template>
                </template>
            </ul>
        </div>
    </div>
</template>

<script setup>
import { useFormatDate } from '~/composables/useFormatDate'
import { authorName, authorJobTitle, authorArea } from '~/siteConfig'

const route = useRoute()
const { formatDate } = useFormatDate()
const { moveTag } = useTag()

// <time datetime> 用。ISO 8601（タイムゾーン付き）で出す
const isoDate = (value) => {
    if (!value) return undefined
    const d = value instanceof Date ? value : new Date(value)
    return Number.isNaN(d.getTime()) ? undefined : d.toISOString()
}

// 目次の表示状態
const isTocVisible = ref(false)

// 見出しのスクロール機能
const scrollToHeading = (id) => {
    const element = document.getElementById(id)
    if (element) {
        element.scrollIntoView({ behavior: 'smooth' })
        // モバイル表示時は目次を閉じる
        if (window.innerWidth < 1024) {
            isTocVisible.value = false
        }
    }
}

// コンテンツの取得
const { data: post } = await useAsyncData('post', () => {
    return queryCollection('posts').path(route.path).first()
})

// データが存在しない場合のエラーハンドリング
if (!post.value) {
    throw createError({
        statusCode: 404,
        message: '記事が見つかりません',
    })
}

// 関連記事の取得
const { data: categoryPost } = await useAsyncData('categoryPost', () => {
    if (post.value?.categories) {
        return queryCollection('posts')
            .select('path', 'title', 'description', 'date', 'image', 'tags')
            .where('categories', 'LIKE', `%${post.value.categories[0]}%`)
            .where('path', '!=', route.path)
            .order('date', 'DESC')
            .limit(3)
            .all()
    }
    return []
})

// meta: canonical / OGP / Twitter カード / article:published_time をまとめて出力する。
// description は frontmatter のものを使う（従来はサイト共通文が出ていた）
usePageSeo({
    title: post.value?.title,
    description: post.value?.description,
    image: post.value?.image || undefined,
    type: 'article',
    publishedTime: post.value?.date,
    modifiedTime: post.value?.updated || post.value?.date,
})

const breadcrumbItems = computed(() => [
    { name: 'ホーム', path: '/' },
    { name: 'ブログ', path: '/posts' },
    { name: post.value?.title, path: route.path },
])

// AEO: 構造化データ（BlogPosting + BreadcrumbList。著者・サイトは @id でサイト全体の Person / WebSite を参照）
const { articleJsonLd, breadcrumbJsonLd, injectJsonLd } = useStructuredData()
injectJsonLd(articleJsonLd(post.value))
injectJsonLd(breadcrumbJsonLd(breadcrumbItems.value))

// 画面サイズに応じて目次の表示状態を制御
onMounted(() => {
    // デスクトップ表示時は目次を表示
    isTocVisible.value = window.innerWidth >= 1024
})

// 画面サイズ変更時の処理
onMounted(() => {
    window.addEventListener('resize', () => {
        if (window.innerWidth >= 1024) {
            isTocVisible.value = true
        }
    })
})
</script>

<style scoped>
/* 目次のスタイル */
.pl-2 {
    padding-left: 0.5rem;
}
.pl-4 {
    padding-left: 1rem;
}
.pl-6 {
    padding-left: 1.5rem;
}
.pl-8 {
    padding-left: 2rem;
}
.pl-10 {
    padding-left: 2.5rem;
}
.pl-12 {
    padding-left: 3rem;
}

/* モバイル表示時の背景オーバーレイ */
@media (max-width: 1023px) {
    .translate-x-0 {
        background-color: rgba(255, 255, 255, 0.95);
    }
}
</style>
