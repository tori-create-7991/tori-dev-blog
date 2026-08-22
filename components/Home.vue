<template>
  <div>
    <!-- Hero -->
    <section class="relative">
      <div class="w-full h-[45vh] relative">
        <NuxtImg
          :src="heroImage"
          class="absolute inset-0 w-full h-full object-cover"
          :modifiers="{ format: 'webp', quality: 80 }"
          alt="Hero background"
        />
        <div class="absolute inset-0 bg-black/40 flex items-center justify-center">
          <div class="text-center text-white px-4">
            <p class="font-display text-2xl sm:text-3xl font-bold">{{ siteConfig.welcomeMessage }}</p>
          </div>
        </div>
      </div>
    </section>

    <div class="mx-auto max-w-screen-xl px-4">
      <!-- Works抜粋 -->
      <section class="py-12">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-xl font-bold text-gray-900">実績</h2>
          <NuxtLink to="/works" class="text-sm text-violet-800 hover:underline">すべて見る</NuxtLink>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <UCard v-for="work in latestWorks" :key="work.path">
            <NuxtLink :to="work.path" class="block">
              <span class="text-xs font-medium text-violet-800">{{ categoryLabel(work.category) }}</span>
              <h3 class="mt-1 font-semibold text-gray-900">{{ work.title }}</h3>
              <p class="mt-2 text-sm text-gray-600 line-clamp-2">{{ work.description }}</p>
            </NuxtLink>
          </UCard>
        </div>
      </section>

      <!-- Service抜粋 -->
      <section class="py-12 border-t border-gray-200">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-xl font-bold text-gray-900">Service</h2>
          <NuxtLink to="/service" class="text-sm text-violet-800 hover:underline">すべて見る</NuxtLink>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <UCard v-for="item in services" :key="item.path">
            <NuxtLink :to="item.path" class="block">
              <span class="text-xs font-medium text-violet-800">{{ serviceCategoryLabel(item.category) }}</span>
              <h3 class="mt-1 font-semibold text-gray-900">{{ item.title }}</h3>
              <p class="mt-2 text-sm text-gray-600 line-clamp-2">{{ item.description }}</p>
            </NuxtLink>
          </UCard>
        </div>
      </section>

      <!-- 最新blog -->
      <section class="py-12 border-t border-gray-200">
        <div class="flex items-center justify-between mb-6">
          <h2 class="font-display text-xl font-bold text-gray-900">最新の記事</h2>
          <NuxtLink to="/posts" class="text-sm text-violet-800 hover:underline">すべて見る</NuxtLink>
        </div>
        <ArticleList :articles="latestPosts" />
      </section>

      <!-- About要約 -->
      <section class="py-12 border-t border-gray-200">
        <h2 class="font-display text-xl font-bold text-gray-900 mb-3">About</h2>
        <p class="text-gray-600 leading-relaxed max-w-2xl">
          {{ siteConfig.description }}
        </p>
        <NuxtLink to="/about" class="mt-3 inline-block text-sm text-violet-800 hover:underline">
          プロフィールを見る
        </NuxtLink>
      </section>

      <!-- 接点 -->
      <section class="py-12 border-t border-gray-200 text-center">
        <h2 class="font-display text-xl font-bold text-gray-900 mb-3">お問い合わせ</h2>
        <p class="text-gray-600 mb-6">AI 導入・DX に関するご相談はこちらから。</p>
        <UButton to="/contact" color="secondary" size="lg">
          お問い合わせ
        </UButton>
      </section>
    </div>
  </div>
</template>

<script setup>
import { siteConfig, workCategoryLabel, serviceCategoryLabel } from '~/siteConfig'
import ArticleList from '~/components/ArticleList.vue'

const heroImage = '/default.jpg'

const { data: works } = await useAsyncData('home-works', () => {
  return queryCollection('works').order('date', 'DESC').limit(3).all()
})
const latestWorks = computed(() => works.value || [])

const { data: servicesData } = await useAsyncData('home-services', () => {
  return queryCollection('service').all()
})
const services = computed(() => servicesData.value || [])

const { data: posts } = await useAsyncData('home-posts', () => {
  return queryCollection('posts').order('date', 'DESC').limit(3).all()
})
const latestPosts = computed(() => posts.value || [])

const categoryLabel = workCategoryLabel
</script>
