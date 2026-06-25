<template>
  <div>
    <div class="mb-4 text-lg font-semibold">
      カテゴリー: すべて
    </div>
    <section>
      <ArticleList
        :articles="allPosts"
      />
    </section>
  </div>
</template>

<script setup>
const mainStore = useStore()

const { data: allPosts } = await useAsyncData('all-posts', () =>
    queryCollection('posts')
        .order('id', 'DESC')
        .all()
)

console.log(allPosts.value)

mainStore.setCategoryPost(allPosts.value)
</script>

<style>
.search-from {
  color: #000;
  background-color: cornsilk;
}

.content-meta {
  display: flex;
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
}
</style>
