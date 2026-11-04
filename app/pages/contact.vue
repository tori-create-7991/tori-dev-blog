<template>
    <article class="mx-auto max-w-screen-md px-4 py-10">
        <h1 class="font-display text-2xl font-bold text-gray-900 dark:text-white">Contact</h1>
        <p class="mt-2 text-sm text-gray-600 dark:text-gray-300">
            連絡は下のフォームからどうぞ。
        </p>

        <div class="prose max-w-none mt-8">
            <ContentRenderer :value="post" />
        </div>
    </article>
</template>

<script setup>
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
    title: 'Contact',
    description: 'tori-dev への連絡フォーム。',
})
</script>
