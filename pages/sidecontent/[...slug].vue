<template>
    <article class="mx-10">
        <div>
            <div class="prose max-w-none">
                <ContentRenderer :value="post" />
            </div>
        </div>
    </article>
</template>

<script setup>

const route = useRoute()

// コンテンツの取得
const { data: post } = await useAsyncData(route.path, () => {
    return queryCollection('sideContent').path(route.path).first()
})

// データが存在しない場合のエラーハンドリング
if (!post.value) {
    throw createError({
        statusCode: 404,
        message: 'ページが見つかりません',
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

// AEO: aboutページのみPersonの構造化データを注入
if (route.path === '/sidecontent/about') {
    const { personJsonLd, injectJsonLd } = useStructuredData()
    injectJsonLd(personJsonLd())
}
</script>
