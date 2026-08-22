<template>
    <article class="mx-10">
        <div>
            <h1
                class="text-2xl font-bold text-center py-4 px-12 mb-4 text-white bg-blue-300 rounded-full"
            >
                {{ post?.title }}
            </h1>
            <div class="bg-blue-50 text-center">
                <p>
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
                        alt="Default announcement image"
                    />
                </p>
            </div>
            <div class="flex flex-col space-y-2 my-4">
                <div class="text-center">
                    Created Day {{ formatDate(post?.date) }}
                </div>
            </div>
            <div>
                <div class="prose max-w-none">
                    <ContentRenderer :value="post" />
                </div>
                <div v-if="recentAnnouncements" class="mt-20 mb-20">
                    <h2 class="text-2xl font-bold mb-8 text-center">
                        最近のお知らせ
                    </h2>
                    <div
                        class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-3 xl:grid-cols-3 gap-4"
                    >
                        <div
                            v-for="n in recentAnnouncements"
                            :key="n.slug"
                            class="bg-white rounded-lg shadow-md overflow-hidden dark:bg-[#121212]"
                        >
                            <div class="p-4">
                                <NuxtLink
                                    :to="'/announcements/' + n.slug"
                                    class="block"
                                >
                                    <NuxtImg
                                        v-if="n.image"
                                        :src="n.image"
                                        class="w-full h-48 object-cover rounded"
                                        :placeholder="[50, 25, 75, 5]"
                                        loading="lazy"
                                    />
                                    <NuxtImg
                                        v-else
                                        :src="defaultImage"
                                        class="w-full h-48 object-cover rounded"
                                        :placeholder="[50, 25, 75, 5]"
                                        loading="lazy"
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
                                <div class="mt-4 text-gray-600 dark:text-gray-300">
                                    {{ formatDate(n.date) }}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </article>
</template>

<script setup>
import { siteConfig } from '~/siteConfig'
import { useFormatDate } from '~/composables/useFormatDate'

const route = useRoute()
const defaultImage = ref(siteConfig.defaultImage)
const { formatDate } = useFormatDate()

// コンテンツの取得
const { data: post } = await useAsyncData('post', () => {
    return queryCollection('announcements').path(route.path).first()
})

// データが存在しない場合のエラーハンドリング
if (!post.value) {
    throw createError({
        statusCode: 404,
        message: 'お知らせが見つかりません',
    })
}

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
</script>
