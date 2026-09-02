<template>
    <article class="mx-auto max-w-screen-md px-4 py-10">
        <h1 class="font-display text-2xl font-bold text-gray-900 dark:text-white">プライバシーポリシー等</h1>
        <div class="prose max-w-none mt-8">
            <ContentRenderer :value="post" />
        </div>
    </article>
</template>

<script setup>
const { data: post } = await useAsyncData('/policy', () => {
    return queryCollection('sideContent').path('/policy').first()
})

if (!post.value) {
    throw createError({
        statusCode: 404,
        message: 'ページが見つかりません',
    })
}

usePageSeo({
    title: 'プライバシーポリシー等',
    description: '当サイトのプライバシーポリシー、免責事項、外部送信に関する記載。',
})
</script>
