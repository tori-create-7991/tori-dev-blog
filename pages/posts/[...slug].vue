<template>
    <div class="flex flex-col lg:flex-row">
        <!-- 目次トグルボタン -->
        <div v-if="!isTocVisible">
            <button
                @click="isTocVisible = !isTocVisible"
                class="fixed right-4 top-15 bg-white text-gray-600 px-3 py-1.5 rounded-md shadow-sm border border-gray-200 hover:bg-gray-50 transition-colors duration-200"
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
                'mx-0 lg:mx-auto lg:max-w-screen-2xl lg:w-full',
                isTocVisible ? 'lg:pr-72' : ''
            ]"
        >
            <div>
                <h1
                    class="text-2xl font-bold text-center py-4 px-12 mb-4 text-white bg-blue-600 rounded-full"
                >
                    {{ post?.title }}
                </h1>
                <div class="bg-blue-50 text-center">
                    <NuxtImg
                        v-if="post?.image"
                        :src="post.image"
                        class="w-full h-72 object-contain"
                        :placeholder="[50, 25, 75, 5]"
                        loading="lazy"
                        :alt="post.title"
                    />
                    <NuxtImg
                        v-else
                        :src="defaultImage"
                        class="w-full h-72 object-contain"
                        :placeholder="[50, 25, 75, 5]"
                        loading="lazy"
                        alt="Default article image"
                    />
                </div>
                <div class="flex flex-col space-y-2 my-4">
                    <div class="flex items-center ml-3">
                        <span class="font-medium">Created Day :</span>
                        <div class="ml-2">{{ formatDate(post?.date) }}</div>
                    </div>
                    <div v-if="post?.updateDate" class="flex items-center ml-3">
                        <span class="font-medium">Update Day :</span>
                        <div class="ml-2">
                            {{ formatDate(post.updateDate) }}
                        </div>
                    </div>
                    <div class="flex flex-wrap gap-2 ml-3">
                        <span
                            v-for="tag in post?.tags"
                            :key="tag"
                            @click="moveTag(tag)"
                            class="px-3 py-1 bg-gray-100 text-gray-800 rounded-full text-sm hover:bg-gray-200 cursor-pointer"
                        >
                            {{ tag }}
                        </span>
                    </div>
                </div>
                <div>
                    <div class="w-full text-base">
                        <ContentRenderer :value="post" />
                    </div>
                    <div v-if="post?.advertisements" class="mt-12">
                        <p class="text-gray-600">広告を表示しています</p>
                        <div
                            v-for="n in post.advertisements"
                            :key="n"
                            v-html="n"
                            class="mt-4"
                        ></div>
                    </div>
                    <div v-if="categoryPost" class="mt-20 mb-20">
                        <div
                            class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-3 xl:grid-cols-3 gap-4"
                        >
                            <div
                                v-for="n in categoryPost"
                                :key="n.slug"
                                class="bg-white rounded-lg shadow-md overflow-hidden"
                            >
                                <div class="p-4">
                                    <NuxtLink :to="n.path" class="block">
                                        <NuxtImg
                                            v-if="n.image"
                                            :src="n.image"
                                            class="w-full h-48 object-cover rounded"
                                            :placeholder="[50, 25, 75, 5]"
                                            loading="lazy"
                                            :alt="n.title"
                                        />
                                        <NuxtImg
                                            v-else
                                            :src="defaultImage"
                                            class="w-full h-48 object-cover rounded"
                                            :placeholder="[50, 25, 75, 5]"
                                            loading="lazy"
                                            alt="Default article image"
                                        />
                                    </NuxtLink>
                                    <h3 class="mt-4 text-lg font-semibold">
                                        <NuxtLink
                                            :to="n.path"
                                            class="text-blue-600 hover:text-blue-800"
                                        >
                                            {{ n.title }}
                                        </NuxtLink>
                                    </h3>
                                    <div class="mt-4 flex items-center">
                                        <div class="text-gray-600">
                                            {{ formatDate(n.date) }}
                                        </div>
                                        <div class="ml-4 flex flex-wrap gap-2">
                                            <span
                                                v-for="tag in n.tags"
                                                :key="tag"
                                                @click="moveTag(tag)"
                                                class="px-2 py-1 bg-gray-100 text-gray-800 rounded-full text-sm hover:bg-gray-200 cursor-pointer"
                                            >
                                                {{ tag }}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </article>

        <!-- サイドバー -->
        <div
            :class="[
                'w-full lg:w-64 fixed lg:right-0 top-0 h-screen overflow-y-auto bg-white p-4 transition-all duration-300',
                isTocVisible ? 'translate-x-0' : 'translate-x-full',
                'mt-20', // ヘッダーの高さ分のマージン
            ]"
        >
            <div class="flex justify-between items-center mb-4">
                <h2 class="text-lg font-bold">目次</h2>
                <button
                    @click="isTocVisible = false"
                    class="text-gray-500 hover:text-gray-700"
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
                            class="text-blue-600 hover:text-blue-800 block py-1"
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
                                class="text-blue-600 hover:text-blue-800 block py-1"
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
import { siteConfig } from '../../siteConfig'
import { useFormatDate } from '~/composables/useFormatDate'

const route = useRoute()
const defaultImage = ref(siteConfig.defaultImage)
const { formatDate } = useFormatDate()
const { moveTag } = useTag()

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
            .where('categories', 'LIKE', `%${post.value.categories[0]}%`)
            .where('path', '!=', route.path)
            .order('date', 'DESC')
            .limit(3)
            .all()
    }
    return []
})

// メタ情報の設定
useHead({
    title: post.value?.title,
    meta: [
        { charset: 'utf-8' },
        { hid: 'og:title', property: 'og:title', content: post.value?.title },
        {
            hid: 'og:image',
            property: 'og:image',
            content: post.value?.image,
        },
    ],
})

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
