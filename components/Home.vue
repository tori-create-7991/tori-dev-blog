<template>
  <div>
    <!-- Hero: 売り文句は置かず「誰が・何をしているか」だけを静的に示す。
         背景は CSS のみ(画像なし)。LCP 要素は H1 テキスト。 -->
    <section class="hero" aria-labelledby="hero-title">
      <div class="hero-inner">
        <p class="hero-eyebrow">{{ authorArea }} / フリーランスエンジニア</p>

        <h1 id="hero-title" class="hero-title">
          {{ authorName }}
          <span class="hero-title-sub">{{ authorAlternateName }}</span>
        </h1>

        <p class="hero-lede">技術顧問・開発・講師をしています。</p>

        <ul class="hero-roles">
          <li v-for="role in heroRoles" :key="role.to" class="hero-role">
            <NuxtLink :to="role.to" class="hero-role-link">
              <span class="hero-role-name">{{ role.name }}</span>
              <span class="hero-role-desc">{{ role.desc }}</span>
            </NuxtLink>
          </li>
        </ul>

        <div class="hero-cta">
          <NuxtLink class="hero-btn hero-btn--ghost" to="/works">実績を見る</NuxtLink>
          <NuxtLink class="hero-btn hero-btn--ghost" to="/contact">お問い合わせ</NuxtLink>
        </div>
      </div>
    </section>

    <div class="mx-auto max-w-screen-xl px-4">
      <!-- Works抜粋 -->
      <section class="py-12">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-xl font-bold text-gray-900 dark:text-white">実績</h2>
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

      <!-- Service抜粋 -->
      <section class="py-12 border-t border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-xl font-bold text-gray-900 dark:text-white">サービス</h2>
          <NuxtLink to="/service" class="text-sm text-[#A2A897] hover:underline">すべて見る</NuxtLink>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <UCard v-for="item in services" :key="item.path">
            <NuxtLink :to="item.path" class="block">
              <span class="text-xs font-medium text-[#A2A897]">{{ serviceCategoryLabel(item.category) }}</span>
              <h3 class="mt-1 font-semibold text-gray-900 dark:text-white">{{ item.title }}</h3>
              <p class="mt-2 text-sm text-gray-600 line-clamp-2 dark:text-gray-300">{{ item.description }}</p>
            </NuxtLink>
          </UCard>
        </div>
      </section>

      <!-- 最新blog -->
      <section class="py-12 border-t border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-xl font-bold text-gray-900 dark:text-white">最新の記事</h2>
          <NuxtLink to="/posts" class="text-sm text-[#A2A897] hover:underline">すべて見る</NuxtLink>
        </div>
        <ArticleList :articles="latestPosts" />
      </section>

      <!-- About要約 -->
      <section class="py-12 border-t border-gray-200 dark:border-gray-700">
        <h2 class="font-display text-xl font-bold text-gray-900 mb-3 dark:text-white">プロフィール</h2>
        <p class="text-gray-600 leading-relaxed max-w-2xl dark:text-gray-300">
          {{ authorArea }}在住のフリーランスエンジニア。中小企業の技術顧問、業務システム開発、プログラミング講師をしています。
        </p>
        <NuxtLink to="/about" class="mt-3 inline-block text-sm text-[#A2A897] hover:underline">
          プロフィールを見る
        </NuxtLink>
      </section>

      <!-- 接点 -->
      <section class="py-12 border-t border-gray-200 text-center dark:border-gray-700">
        <h2 class="font-display text-xl font-bold text-gray-900 mb-3 dark:text-white">お問い合わせ</h2>
        <p class="text-gray-600 mb-6 dark:text-gray-300">お仕事のご相談・お問い合わせはこちらから。</p>
        <UButton to="/contact" color="secondary" size="lg">
          お問い合わせ
        </UButton>
      </section>
    </div>
  </div>
</template>

<script setup>
import {
  siteConfig,
  workCategoryLabel,
  serviceCategoryLabel,
  authorName,
  authorAlternateName,
  authorArea,
} from '~/siteConfig'
import ArticleList from '~/components/ArticleList.vue'

// ヒーローに並べる役割。各サービスページへの入口を兼ねる
const heroRoles = [
  { name: '技術顧問', desc: '中小企業の AI 導入・DX', to: siteConfig.advisoryPath },
  { name: '開発', desc: '業務システム・Web アプリ', to: '/service/development' },
  { name: '講師', desc: 'プログラミング研修・ブートキャンプ', to: '/service/training' },
]

const { data: works } = await useAsyncData('home-works', () => {
  return queryCollection('works').select('path', 'title', 'description', 'category', 'date').order('date', 'DESC').limit(3).all()
})
const latestWorks = computed(() => works.value || [])

const { data: servicesData } = await useAsyncData('home-services', () => {
  return queryCollection('service').select('path', 'title', 'description', 'category').all()
})
const services = computed(() => servicesData.value || [])

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
.hero-eyebrow {
  margin: 0 0 1rem;
  font-size: 0.8rem;
  letter-spacing: 0.12em;
  color: #a2a897; /* 7.66:1 */
}

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
.hero-title-sub {
  margin-left: 0.5em;
  font-weight: 400;
  font-size: 0.5em;
  letter-spacing: 0.04em;
  color: #a2a897; /* 7.66:1 */
}

.hero-lede {
  margin: 1.25rem 0 0;
  max-width: 46ch;
  color: #c9ccc0; /* 11.49:1 */
  line-height: 1.9;
  font-size: clamp(0.95rem, 2.4vw, 1.05rem);
}

/* ---------- 役割 ---------- */
.hero-roles {
  display: grid;
  gap: 0.5rem;
  margin: 2rem 0 0;
  padding: 0;
  list-style: none;
  max-width: 46ch;
}
.hero-role-link {
  display: flex;
  align-items: baseline;
  gap: 0.75rem;
  padding: 0.35rem 0;
  text-decoration: none;
  color: #e5e5e0; /* 14.82:1 */
  font-size: clamp(0.95rem, 2.4vw, 1.05rem);
  line-height: 1.7;
}
.hero-role-link::before {
  content: "";
  flex: none;
  align-self: flex-start;
  margin-top: 0.7em; /* 説明が2行に折り返しても1行目に揃える */
  width: 6px;
  height: 6px;
  background: #a2a897;
  transform: rotate(45deg);
}
.hero-role-name {
  flex: none;
  min-width: 4.5em;
  font-weight: 600;
  color: #f4f4f1;
}
.hero-role-desc { color: #c9ccc0; /* 11.49:1 */ }
.hero-role-link:hover .hero-role-name,
.hero-role-link:hover .hero-role-desc { color: #a2a897; }
.hero-role-link:focus-visible {
  outline: 2px solid #a2a897;
  outline-offset: 2px;
}

/* ---------- CTA ---------- */
.hero-cta {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-top: 2.25rem;
}
.hero-btn {
  display: inline-block;
  padding: 0.7rem 1.4rem;
  border-radius: 0.5rem;
  text-decoration: none;
  font-size: 0.9rem;
  font-weight: 600;
}
.hero-btn--ghost {
  border: 1px solid #4d4d4d;
  color: #c9ccc0;
}
.hero-btn--ghost:hover {
  border-color: #a2a897;
  color: #a2a897;
}
.hero-btn:focus-visible {
  outline: 2px solid #a2a897;
  outline-offset: 2px;
}
</style>
