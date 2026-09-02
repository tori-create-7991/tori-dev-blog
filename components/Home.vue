<template>
  <div>
    <!-- Hero: 誰に・何を提供する誰か をファーストビューで完結させる。
         6.1MB の背景写真は LCP を殺していたため撤去し、CSS だけで構成した。
         H1 は SEO/AEO 上の中核なので絶対にアニメーションさせない。
         提供価値の 1 行だけを回転させ、停止コントロールを付ける
         (WCAG 2.2 SC 2.2.2 レベルA。4 件は常に DOM にあるので
          スクリーンリーダーと JS を実行しない AI クローラは全件を読める) -->
    <section class="hero" aria-labelledby="hero-title">
      <div class="hero-inner">
        <p class="hero-eyebrow">
          {{ authorName }} / {{ authorAlternateName }} — {{ authorArea }}
        </p>

        <h1 id="hero-title" class="hero-title">
          中小企業の<span class="hero-accent">AI 導入・DX</span> を、<br class="hero-br">現場に入って伴走する技術顧問
        </h1>

        <p class="hero-lede">
          ERP の開発・導入支援とりんご農園の受注分析で現場を回しながら、コーディングブートキャンプでも教えています。
          ツールを入れて終わりにせず、運用が定着するまで月次で伴走します。
        </p>

        <div class="hero-rot">
          <!-- 停止トグル。DOM 上はローテーションより前＝タブ順で先に来る -->
          <input id="hero-pause" class="hero-pause-input" type="checkbox" role="switch">
          <label class="hero-pause" for="hero-pause">
            <span class="hero-pause-icon" aria-hidden="true"></span>
            <span class="hero-pause-text">自動切り替えを停止</span>
          </label>

          <ul class="hero-rot-track">
            <li v-for="value in heroValues" :key="value" class="hero-rot-item">{{ value }}</li>
          </ul>
        </div>

        <div class="hero-cta">
          <NuxtLink class="hero-btn hero-btn--primary" to="/contact">相談する</NuxtLink>
          <NuxtLink class="hero-btn hero-btn--ghost" to="/works">実績を見る</NuxtLink>
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
          {{ siteConfig.description }}
        </p>
        <NuxtLink to="/about" class="mt-3 inline-block text-sm text-[#A2A897] hover:underline">
          プロフィールを見る
        </NuxtLink>
      </section>

      <!-- 接点 -->
      <section class="py-12 border-t border-gray-200 text-center dark:border-gray-700">
        <h2 class="font-display text-xl font-bold text-gray-900 mb-3 dark:text-white">お問い合わせ</h2>
        <p class="text-gray-600 mb-6 dark:text-gray-300">AI 導入・DX に関するご相談はこちらから。</p>
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

// ヒーローで回転させる提供価値。4 件すべてが常に DOM に存在する
const heroValues = [
  'AI 導入支援 — 業務の棚卸しから PoC、社内展開まで',
  'DX 顧問 — 経営と現場の間に立ち、続く仕組みを作る',
  '研修・講師 — 生成 AI を「使える」状態にする実践型',
  '開発 — 小さく作って、確かめながら育てる',
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
.hero-accent { color: #a2a897; }
.hero-br { display: none; }
@media (min-width: 640px) {
  .hero-br { display: inline; }
}

.hero-lede {
  margin: 1.25rem 0 0;
  max-width: 46ch;
  color: #c9ccc0; /* 11.49:1 */
  line-height: 1.9;
  font-size: clamp(0.95rem, 2.4vw, 1.05rem);
}

/* ---------- 提供価値のローテーション ---------- */
.hero-rot {
  display: flex;
  align-items: flex-start;
  gap: 0.75rem;
  margin-top: 2rem;
  max-width: 46ch;
}

/* チェックボックス本体は視覚的に隠すがフォーカス可能なまま残す */
.hero-pause-input {
  position: absolute;
  width: 1px;
  height: 1px;
  margin: -1px;
  padding: 0;
  border: 0;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
.hero-pause {
  order: 2; /* 見た目は右、タブ順は先頭のまま */
  flex: none;
  display: inline-grid;
  place-items: center;
  width: 2.25rem;
  height: 2.25rem;
  border-radius: 999px;
  /* #4d4d4d は #121212 上で 3:1 以上。#333 は 1.48:1 で境界として成立しない */
  border: 1px solid #4d4d4d;
  background: #272727;
  color: #c9ccc0;
  cursor: pointer;
}
.hero-pause:hover {
  border-color: #a2a897;
  color: #a2a897;
}
.hero-pause-input:focus-visible + .hero-pause {
  outline: 2px solid #a2a897;
  outline-offset: 2px;
}
/* 未チェック=一時停止(❚❚) / チェック済=再生(▶) */
.hero-pause-icon {
  width: 0.6rem;
  height: 0.7rem;
  border-left: 3px solid currentColor;
  border-right: 3px solid currentColor;
}
.hero-pause-input:checked + .hero-pause .hero-pause-icon {
  width: 0;
  height: 0;
  border: none;
  border-left: 0.6rem solid currentColor;
  border-block: 0.38rem solid transparent;
}
.hero-pause-text {
  position: absolute;
  width: 1px;
  height: 1px;
  margin: -1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}

.hero-rot-track {
  order: 1;
  position: relative;
  flex: 1;
  min-width: 0;
  margin: 0;
  padding: 0;
  list-style: none;
  /* CLS 防止に 2 行分を確保する */
  min-block-size: 3.5rem;
}
@media (max-width: 480px) {
  .hero-rot-track { min-block-size: 4.75rem; }
}

.hero-rot-item {
  display: flex;
  align-items: flex-start;
  gap: 0.6rem;
  color: #e5e5e0; /* 14.82:1 */
  font-size: clamp(0.9rem, 2.4vw, 1rem);
  line-height: 1.7;
}
.hero-rot-item::before {
  content: "";
  flex: none;
  margin-top: 0.55em;
  width: 6px;
  height: 6px;
  background: #a2a897;
  transform: rotate(45deg);
}

@media (prefers-reduced-motion: no-preference) {
  .hero-rot-track > .hero-rot-item {
    position: absolute;
    inset-inline: 0;
    inset-block-start: 0;
    opacity: 0;
    animation: hero-fade 24s linear infinite; /* 4 件 x 6s */
  }
  .hero-rot-track > .hero-rot-item:nth-child(1) { animation-delay: 0s; }
  .hero-rot-track > .hero-rot-item:nth-child(2) { animation-delay: 6s; }
  .hero-rot-track > .hero-rot-item:nth-child(3) { animation-delay: 12s; }
  .hero-rot-track > .hero-rot-item:nth-child(4) { animation-delay: 18s; }

  /* 明示的な停止（SC 2.2.2 を満たす手段） */
  .hero-pause-input:checked ~ .hero-rot-track > .hero-rot-item { animation-play-state: paused; }
  /* hover / フォーカス中も止める（W3C WAI カルーセルチュートリアルの要求） */
  .hero:hover .hero-rot-track > .hero-rot-item,
  .hero:focus-within .hero-rot-track > .hero-rot-item { animation-play-state: paused; }
}

/* 動きを減らす設定では回転せず 4 件を縦に並べる（情報の欠落なし） */
@media (prefers-reduced-motion: reduce) {
  .hero-rot { display: block; }
  .hero-rot-track { display: grid; gap: 0.5rem; min-block-size: 0; }
  .hero-pause,
  .hero-pause-input { display: none; }
}

/* 24s 周期を 4 件で分割し、各件が約 5.3s 表示される。
   0% を表示状態から始めることで、delay 0 の 1 件目が初回描画から見える
   （0% を非表示にすると起動直後に 4 件とも消えている区間ができる）。 */
@keyframes hero-fade {
  0%, 22% { opacity: 1; }
  24%, 98% { opacity: 0; }
  100% { opacity: 1; }
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
.hero-btn--primary {
  background: #a2a897;
  color: #121212; /* 反転で 7.66:1 */
}
.hero-btn--primary:hover { background: #8b9179; }
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
