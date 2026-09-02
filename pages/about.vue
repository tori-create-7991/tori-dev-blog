<template>
    <article class="mx-auto max-w-screen-md px-4 py-10">
        <h1 class="font-display text-2xl sm:text-3xl font-bold text-gray-900 dark:text-white">
            {{ authorName }} — {{ authorJobTitle }}
        </h1>
        <p class="mt-2 text-sm text-gray-600 dark:text-gray-300">{{ authorArea }}在住 / {{ authorAlternateName }}</p>

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
            <h2 class="font-display text-lg font-semibold text-gray-900 dark:text-white">ご相談</h2>
            <p class="mt-2 text-sm text-gray-600 dark:text-gray-300">
                AI 導入・DX、研修、開発のご相談は
                <NuxtLink to="/contact" class="text-[#A2A897] hover:underline">お問い合わせ</NuxtLink>
                から受け付けています。
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
    title: 'プロフィール',
    description: `${authorName}（${authorAlternateName}）のプロフィール。${authorArea}在住のフリーランスエンジニア。中小企業の AI 導入・DX 支援、ERP 開発、プログラミング講師。`,
})

// ProfilePage + Person。Person 実体はサイト全体で共有し @id で参照する
const { profilePageJsonLd, breadcrumbJsonLd, injectJsonLd } = useStructuredData()
injectJsonLd(profilePageJsonLd())
injectJsonLd(
    breadcrumbJsonLd([
        { name: 'ホーム', path: '/' },
        { name: 'プロフィール', path: '/about' },
    ])
)
</script>
