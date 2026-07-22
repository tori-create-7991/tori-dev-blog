<template>
  <div class="tweets-page">
    <h1 class="page-title">つぶやき</h1>
    <p class="page-sub">X・Bluesky・Threads への投稿ログ（text-sns-relay 連携）</p>

    <ul class="tweet-list">
      <li v-for="tweet in tweets" :key="tweet.path" class="tweet-card">
        <p class="tweet-text">{{ tweet.text }}</p>
        <div class="tweet-meta">
          <span class="tweet-date">{{ formatDate(tweet.postedAt) }}</span>
          <a v-if="tweet.urlX" :href="tweet.urlX" target="_blank" rel="noopener" class="badge badge-x">X</a>
          <a v-if="tweet.urlBluesky" :href="tweet.urlBluesky" target="_blank" rel="noopener" class="badge badge-bsky">Bluesky</a>
          <a v-if="tweet.urlThreads" :href="tweet.urlThreads" target="_blank" rel="noopener" class="badge badge-threads">Threads</a>
        </div>
      </li>
    </ul>

    <p v-if="!tweets?.length" class="empty">まだつぶやきがありません。</p>
  </div>
</template>

<script setup>
import { useFormatDate } from '~/composables/useFormatDate'

const { formatDate } = useFormatDate()

const { data: tweets } = await useAsyncData('tweets', () => {
  return queryCollection('tweets').order('postedAt', 'DESC').all()
})

useHead({
  title: 'つぶやき',
  meta: [
    { name: 'description', content: 'X・Bluesky・Threads への投稿ログ' },
  ],
})
</script>

<style scoped>
.tweets-page {
  max-width: 680px;
  margin: 0 auto;
}
.page-title {
  font-size: 1.8rem;
  font-weight: 700;
  color: #1f2937;
}
.page-sub {
  color: #6b7280;
  margin-top: 0.25rem;
  margin-bottom: 2rem;
}
.tweet-list {
  list-style: none;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}
.tweet-card {
  background: #fff;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 1rem 1.25rem;
}
.tweet-text {
  color: #1f2937;
  line-height: 1.7;
  white-space: pre-wrap;
}
.tweet-meta {
  margin-top: 0.75rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  flex-wrap: wrap;
}
.tweet-date {
  font-size: 0.8rem;
  color: #9ca3af;
  margin-right: 0.25rem;
}
.badge {
  font-size: 0.75rem;
  font-weight: 600;
  padding: 0.2rem 0.6rem;
  border-radius: 9999px;
  text-decoration: none !important;
}
.badge-x { background: #e6f1fb; color: #185fa5; }
.badge-bsky { background: #eaf3de; color: #3b6d11; }
.badge-threads { background: #eeedfe; color: #534ab7; }
.empty {
  color: #9ca3af;
  text-align: center;
  padding: 2rem 0;
}
</style>
