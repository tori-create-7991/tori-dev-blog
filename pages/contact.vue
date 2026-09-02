<template>
    <article class="mx-auto max-w-screen-md px-4 py-10">
        <h1 class="font-display text-2xl font-bold text-gray-900 dark:text-white">お問い合わせ</h1>
        <p class="mt-2 text-sm text-gray-600 dark:text-gray-300">
            AI 導入・DX の顧問、研修・登壇、開発のご相談を受け付けています。全国オンライン対応（拠点は{{ authorArea }}）。
        </p>

        <div class="prose max-w-none mt-8">
            <ContentRenderer :value="post" />
        </div>
    </article>
</template>

<script setup>
import { authorArea } from '~/siteConfig'

const { data: post } = await useAsyncData('/contact', () => {
    return queryCollection('sideContent').path('/contact').first()
})

if (!post.value) {
    throw createError({
        statusCode: 404,
        message: 'ページが見つかりません',
    })
}

usePageSeo({
    title: 'お問い合わせ',
    description: 'AI 導入・DX 顧問、研修・登壇、開発のご相談窓口。全国オンライン対応。',
})
</script>
