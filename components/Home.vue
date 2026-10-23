<template>
  <div>
    <!-- Hero: 個人サイトなので氏名・居住地・営業導線は置かず、サイト名と一言だけ。
         氏名などは /about に集約する。背景は CSS のみ(画像なし)。LCP 要素は H1 テキスト。 -->
    <section class="hero" aria-labelledby="hero-title">
      <div class="hero-inner">
        <h1 id="hero-title" class="hero-title">{{ siteConfig.siteTitle }}</h1>
        <p class="hero-lede">技術メモ、つぶやき、つくったもの。</p>
      </div>
    </section>

    <div class="mx-auto max-w-screen-xl px-4">
      <!-- 最新blog -->
      <section class="py-12">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-xl font-bold text-gray-900 dark:text-white">Blog</h2>
          <NuxtLink to="/posts" class="text-sm text-[#A2A897] hover:underline">すべて見る</NuxtLink>
        </div>
        <ArticleList :articles="latestPosts" />
      </section>

      <!-- Works抜粋 -->
      <section class="py-12 border-t border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-xl font-bold text-gray-900 dark:text-white">Works</h2>
          <NuxtLink to="/works" class="text-sm text-[#A2A897] hover:underline">すべて見る</NuxtLink>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <UCard v-for="work in latestWorks" :key="work.path">
            <NuxtLink :to="work.path" class="block">
              <span class="text-xs font-medium text-[#A2A897]">{{ categoryLabel(work.category) }}</span>
              <h3 class="mt-1 font-semibold text-gray-900 dark:text-white">{{ work.title }}</h3>
              <p class="mt-2 text-sm text-gray-600 line-clamp-2 dark:text-gray-300">{{ work.description }}</p>
            </NuxtLink>
          </UCard>
        </div>
      </section>

      <!-- About への導線のみ。自己紹介の中身は /about に置く -->
      <section class="py-12 border-t border-gray-200 dark:border-gray-700">
        <h2 class="font-display text-xl font-bold text-gray-900 mb-3 dark:text-white">About</h2>
        <NuxtLink to="/about" class="text-sm text-[#A2A897] hover:underline">
          書いている人について
        </NuxtLink>
      </section>
    </div>
  </div>
</template>

<script setup>
import { siteConfig, workCategoryLabel } from '~/siteConfig'
import ArticleList from '~/components/ArticleList.vue'

const { data: works } = await useAsyncData('home-works', () => {
  return queryCollection('works').select('path', 'title', 'description', 'category', 'date').order('date', 'DESC').limit(3).all()
})
const latestWorks = computed(() => works.value || [])

const { data: posts } = await useAsyncData('home-posts', () => {
  return queryCollection('posts').select('path', 'title', 'description', 'date', 'image', 'tags').order('date', 'DESC').limit(3).all()
})
const latestPosts = computed(() => posts.value || [])

const categoryLabel = workCategoryLabel
</script>

<style scoped>
/* ================= Hero =================
   画像ファイルを一切使わない。グラデーション + ヘアライングリッド + グレインの 3 層。
   CSS グラデーションは LCP 候補にならないため、LCP 要素は H1 テキストになる。 */
.hero {
  position: relative;
  isolation: isolate;
  overflow: hidden;
  padding: clamp(3.5rem, 10vw, 5.5rem) 1rem clamp(3rem, 8vw, 4.5rem);
  background-color: #121212;
  background-image:
    radial-gradient(60ch 40ch at 12% 8%, rgba(162, 168, 151, 0.13), transparent 70%),
    radial-gradient(50ch 35ch at 88% 92%, rgba(162, 168, 151, 0.07), transparent 70%),
    linear-gradient(180deg, #171717 0%, #121212 55%, #101010 100%);
}

/* ヘアライングリッド。上からフェードさせて主張させない */
.hero::before {
  content: "";
  position: absolute;
  inset: 0;
  z-index: -2;
  pointer-events: none;
  background-image:
    repeating-linear-gradient(to right, rgba(162, 168, 151, 0.08) 0 1px, transparent 1px 96px),
    repeating-linear-gradient(to bottom, rgba(162, 168, 151, 0.08) 0 1px, transparent 1px 96px);
  -webkit-mask-image: radial-gradient(120% 90% at 50% 0%, #000 0%, transparent 75%);
  mask-image: radial-gradient(120% 90% at 50% 0%, #000 0%, transparent 75%);
}

/* グレイン。CSP の img-src 'self' data: で許可される（調査時に実測確認済み） */
.hero::after {
  content: "";
  position: absolute;
  inset: 0;
  z-index: -1;
  pointer-events: none;
  opacity: 0.26;
  mix-blend-mode: soft-light;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='140' height='140'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='3' stitchTiles='stitch'/%3E%3CfeColorMatrix type='saturate' values='0'/%3E%3C/filter%3E%3Crect width='140' height='140' filter='url(%23n)' opacity='0.55'/%3E%3C/svg%3E");
}

.hero-inner {
  max-width: 72rem;
  margin-inline: auto;
}

/* コントラストはすべて #121212 上の実測値。AA(4.5:1)を大きく上回る */
.hero-title {
  margin: 0;
  font-family: var(--font-display), system-ui, sans-serif;
  font-weight: 700;
  font-size: clamp(1.75rem, 5.2vw, 2.85rem);
  line-height: 1.3;
  letter-spacing: -0.01em;
  color: #f4f4f1; /* 17.00:1 */
  word-break: auto-phrase;
}

.hero-lede {
  margin: 1.25rem 0 0;
  max-width: 46ch;
  color: #c9ccc0; /* 11.49:1 */
  line-height: 1.9;
  font-size: clamp(0.95rem, 2.4vw, 1.05rem);
}
</style>
