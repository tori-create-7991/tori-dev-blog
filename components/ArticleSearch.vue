<template>
    <div>
        <div class="mx-10 mb-5 p-2 bg-amber-50">
            <input
                v-model="searchword"
                type="search"
                autocomplete="off"
                placeholder="キーワードを入力してください"
                class="w-full border-2 border-blue-200 rounded p-2"
            />
        </div>

        <div v-if="posts">
            <ArticleList :articles="posts"/>
        </div>
        <div v-else class="text-center py-8">
            <p class="text-gray-600">記事がありません</p>
        </div>
    </div>
</template>

<script setup>
import { useStore } from '~/stores/store'



const store = useStore()
const searchword = ref('')
const posts = computed(() => store.getContents || [])


console.log(posts.value)

watch(searchword, async (newValue) => {
    if (newValue) {
        // const post = await queryCollection("content")
        //   .where({
        //     $text: {
        //       $search: newValue
        //     }
        //   })
        //   .sort({ date: -1 })
        //   .find();
        // const { data: posts } = await useAsyncData('posts', () => {
        //     return queryCollection('posts').all()
        // })

        // store.setContent(posts.value)
        // console.log(posts.value)
    }
})


</script>

<style>
.search-area {
    color: #000;
    background-color: cornsilk;
    margin-left: 10%;
    margin-right: 10%;
    margin-bottom: 5%;
    padding: 1%;
}
.search-from {
    width: 100%;
    border-color: aqua;
}
.content-meta {
    display: flex;
    /* justify-content: space-around; */
}

.card-tags {
    margin-left: 5%;
}

.card-created-day {
    margin-top: 3%;
    margin-left: 5%;
}

.card-img {
    max-height: 200px;
    width: 100%;
    object-fit: cover;
}
</style>
