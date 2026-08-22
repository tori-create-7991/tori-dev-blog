<template>
  <article class="mx-auto max-w-screen-md px-4 py-10">
    <AppBreadcrumb :items="breadcrumbItems" />
    <span class="text-sm font-medium text-[#A2A897]">{{ categoryLabel }}</span>
    <h1 class="mt-2 font-display text-2xl font-bold text-gray-900 dark:text-white">{{ work?.title }}</h1>

    <div class="mt-3 flex flex-wrap gap-3 text-sm text-gray-500 dark:text-gray-400">
      <span v-if="work?.duration">{{ work.duration }}</span>
      <span v-if="work?.role">{{ work.role }}</span>
    </div>

    <div v-if="work?.technologies?.length" class="mt-4 flex flex-wrap gap-2">
      <UBadge v-for="tech in work.technologies" :key="tech" color="neutral" variant="subtle">
        {{ tech }}
      </UBadge>
    </div>

    <div class="prose max-w-none mt-8">
      <ContentRenderer :value="work" />
    </div>

    <div v-if="work?.links?.length" class="mt-8 flex flex-wrap gap-3">
      <UButton
        v-for="link in work.links"
        :key="link.url"
        :to="link.url"
        target="_blank"
        color="secondary"
        variant="outline"
      >
        {{ link.text }}
      </UButton>
    </div>
  </article>
</template>

<script setup>
import { workCategoryLabel } from '~/siteConfig'

const route = useRoute()

const { data: work } = await useAsyncData(route.path, () => {
  return queryCollection('works').path(route.path).first()
})

if (!work.value) {
  throw createError({
    statusCode: 404,
    message: '実績が見つかりません',
  })
}

const categoryLabel = computed(() => workCategoryLabel(work.value?.category))

const breadcrumbItems = computed(() => [
  { name: 'ホーム', path: '/' },
  { name: '実績', path: '/works' },
  { name: work.value?.title, path: route.path },
])

usePageSeo({
  title: work.value?.title,
  description: work.value?.description,
})

// AEO: 構造化データ
const { creativeWorkJsonLd, breadcrumbJsonLd, injectJsonLd } = useStructuredData()
injectJsonLd(creativeWorkJsonLd(work.value))
injectJsonLd(breadcrumbJsonLd(breadcrumbItems.value))
</script>
