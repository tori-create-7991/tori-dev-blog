<template>
    <div>
        <home />
        <div v-if="announcementsFlag"><HomeNews /></div>
    </div>
</template>

<script setup>
import Home from '../components/Home.vue'
import HomeNews from '~/components/HomeNews.vue'
import { announcementsFlag } from '../siteConfig'

const mainStore = useStore()


const { data: announcementsPost } = await useAsyncData('announcements', () => {
    return queryCollection('announcements').all()
})

const { data: posts } = await useAsyncData('posts', () => {
    return queryCollection('posts').all()
})


mainStore.createToc('')
mainStore.setContents(posts.value)
mainStore.setAnnouncementsPost(announcementsPost.value)
</script>

<style scoped></style>
