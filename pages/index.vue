<template>
    <div>
        <home />
        <div v-if="announcementsFlag"><HomeNews /></div>
    </div>
</template>

<script setup>
import Home from '../components/Home.vue'
import HomeNews from '~/components/HomeNews.vue'
import { announcementsFlag, siteConfig } from '../siteConfig'

const mainStore = useStore()


const { data: announcementsPost } = await useAsyncData('announcements', () => {
    return queryCollection('announcements').all()
})

// 一覧表示に必要なフィールドだけ取る。全フィールドを取ると本文 AST まで
// _payload.json に載り、全ページで数百 KB を転送することになる
const { data: posts } = await useAsyncData('posts', () => {
    return queryCollection('posts')
        .select('path', 'title', 'description', 'date', 'image', 'tags', 'categories')
        .order('date', 'DESC')
        .all()
})


// トップは canonical / OGP をここで出す（title はサイト名のみ）
usePageSeo({
    description: siteConfig.description,
    path: '/',
})

mainStore.createToc('')
mainStore.setContents(posts.value)
mainStore.setAnnouncementsPost(announcementsPost.value)
</script>

<style scoped></style>
