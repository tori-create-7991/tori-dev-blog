<template>
  <div class="mx-auto max-w-screen-xl px-4 py-10">
    <h1 class="font-display text-2xl font-bold text-gray-900 mb-2 dark:text-white">実績</h1>
    <p class="mb-8 text-sm text-gray-600 dark:text-gray-300">
      AX・DX 支援、研修講師、開発の実績です。
    </p>

    <section v-for="group in groupedWorks" :key="group.key" class="mb-10">
      <h2 class="font-display text-lg font-semibold text-[#A2A897] mb-4">{{ group.label }}</h2>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        <UCard v-for="work in group.items" :key="work.path">
          <NuxtLink :to="work.path" class="block">
            <h3 class="font-semibold text-gray-900 dark:text-white">{{ work.title }}</h3>
            <p class="mt-2 text-sm text-gray-600 line-clamp-3 dark:text-gray-300">{{ work.description }}</p>
            <p v-if="work.duration" class="mt-3 text-xs text-gray-400">{{ work.duration }}</p>
          </NuxtLink>
        </UCard>
      </div>
    </section>
  </div>
</template>

<script setup>
import { workCategories } from '~/siteConfig'

const { data: works } = await useAsyncData('works-index', () => {
  return queryCollection('works').order('date', 'DESC').all()
})

const groupedWorks = computed(() => {
  const items = works.value || []
  return workCategories
    .map((c) => ({
      ...c,
      items: items.filter((w) => w.category === c.key),
    }))
    .filter((g) => g.items.length > 0)
})

usePageSeo({
  title: '実績',
  description: '中小企業の AX・DX 支援、コーディングブートキャンプ等の研修講師、個人開発の実績一覧。',
})
</script>
