<template>
    <article class="mx-auto max-w-screen-md px-4 py-10">
        <!-- 氏名と肩書きを分け、長い肩書きが h1 内で折り返して読みにくくなるのを防ぐ -->
        <h1 class="font-display text-2xl sm:text-3xl font-bold text-gray-900 dark:text-white">
            {{ authorName }}
            <span class="ml-2 text-base sm:text-lg font-normal text-gray-500 dark:text-gray-400">{{ authorAlternateName }}</span>
        </h1>
        <p class="mt-3 text-sm text-gray-600 dark:text-gray-400">{{ authorJobTitle }} / {{ authorArea }}</p>

        <div class="prose max-w-none mt-8">
            <ContentRenderer :value="post" />
        </div>

        <section v-if="socials.length" class="mt-12">
            <h2 class="font-display text-lg font-semibold text-gray-900 dark:text-white">外部プロフィール</h2>
            <ul class="mt-3 flex flex-wrap gap-4 text-sm">
                <li v-for="profile in socials" :key="profile.key">
                    <!-- rel="me" で各プラットフォームのプロフィールと相互リンクし、本人性を示す -->
                    <a
                        :href="profile.url"
                        rel="me noopener"
                        target="_blank"
                        class="text-[#A2A897] hover:underline"
                    >{{ profile.label }}</a>
                </li>
            </ul>
        </section>

        <section class="mt-12">
            <h2 class="font-display text-lg font-semibold text-gray-900 dark:text-white">連絡</h2>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-300">
                <NuxtLink to="/contact" class="text-[#A2A897] hover:underline">連絡フォーム</NuxtLink>からどうぞ。
            </p>
        </section>
    </article>
</template>

<script setup>
import {
    authorName,
    authorAlternateName,
    authorJobTitle,
    authorArea,
    activeSocialProfiles,
} from '~/siteConfig'

const { data: post } = await useAsyncData('/about', () => {
    return queryCollection('sideContent').path('/about').first()
})

if (!post.value) {
    throw createError({
        statusCode: 404,
        message: 'ページが見つかりません',
    })
}

const socials = activeSocialProfiles()

usePageSeo({
    title: 'About',
    description: `${authorName}（${authorAlternateName}）について。${authorArea}のエンジニア。`,
})

// ProfilePage + Person。Person 実体はサイト全体で共有し @id で参照する
const { profilePageJsonLd, breadcrumbJsonLd, injectJsonLd } = useStructuredData()
injectJsonLd(profilePageJsonLd())
injectJsonLd(
    breadcrumbJsonLd([
        { name: 'ホーム', path: '/' },
        { name: 'About', path: '/about' },
    ])
)
</script>
