<template>
    <article class="mx-auto max-w-screen-md px-4 py-10">
        <div class="prose max-w-none">
            <ContentRenderer :value="post" />
        </div>
    </article>
</template>

<script setup>
const { data: post } = await useAsyncData('/about', () => {
    return queryCollection('sideContent').path('/about').first()
})

if (!post.value) {
    throw createError({
        statusCode: 404,
        message: 'ページが見つかりません',
    })
}

useHead({
    title: post.value?.title,
    meta: [
        { hid: 'og:title', property: 'og:title', content: post.value?.title },
    ],
})

const { personJsonLd, injectJsonLd } = useStructuredData()
injectJsonLd(personJsonLd())
</script>
