<template>
  <div>
    <!-- Hero: 誰に・何を提供する誰か をファーストビューで完結させる。
         背景写真(6.1MB)は LCP を殺していたため撤去し、CSS のグラデーションに置き換えた。
         スライドショー化は別途対応 -->
    <section class="relative isolate overflow-hidden border-b border-gray-200 dark:border-[#333333]">
      <div class="hero-bg absolute inset-0 -z-10" aria-hidden="true"></div>
      <div class="mx-auto max-w-screen-xl px-4 py-16 sm:py-20">
        <p class="text-sm font-medium tracking-wide text-[#A2A897]">
          {{ authorName }} / {{ authorAlternateName }} — {{ authorArea }}
        </p>
        <h1 class="mt-3 font-display text-3xl font-bold leading-tight text-gray-900 sm:text-4xl dark:text-white">
          中小企業の AI 導入・DX を、<br class="hidden sm:block">現場に入って伴走する技術顧問
        </h1>
        <p class="mt-5 max-w-2xl text-base leading-relaxed text-gray-600 dark:text-gray-300">
          ERP の開発・導入支援とりんご農園の受注分析で現場を回しながら、コーディングブートキャンプでも教えています。
          ツールを入れて終わりにせず、運用が定着するまで月次で伴走します。
        </p>
        <div class="mt-8 flex flex-wrap gap-4">
          <UButton to="/contact" color="secondary" size="lg">相談する</UButton>
          <UButton to="/works" color="neutral" variant="outline" size="lg">実績を見る</UButton>
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
/* 画像ファイルを使わない Hero 背景。
   ダークテーマ(#121212)の上に、アクセント色(#A2A897)をごく薄く重ねる */
.hero-bg {
  background-color: #f4f4f1;
  background-image:
    radial-gradient(60rem 30rem at 15% -10%, rgba(162, 168, 151, 0.28), transparent 60%),
    radial-gradient(40rem 24rem at 90% 0%, rgba(162, 168, 151, 0.14), transparent 65%);
}

:root.dark .hero-bg {
  background-color: #121212;
  background-image:
    radial-gradient(55rem 28rem at 12% -12%, rgba(162, 168, 151, 0.22), transparent 62%),
    radial-gradient(38rem 22rem at 92% 4%, rgba(162, 168, 151, 0.10), transparent 68%),
    linear-gradient(180deg, #1d1d1b 0%, #121212 100%);
}
</style>
