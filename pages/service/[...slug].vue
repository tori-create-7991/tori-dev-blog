<template>
  <article class="mx-auto max-w-screen-md px-4 py-10">
    <AppBreadcrumb :items="breadcrumbItems" />
    <span class="text-sm font-medium text-[#A2A897]">{{ categoryLabel }}</span>
    <h1 class="mt-2 font-display text-2xl font-bold text-gray-900 dark:text-white">{{ service?.title }}</h1>
    <p v-if="service?.price" class="mt-2 text-sm text-gray-500 dark:text-gray-400">料金: {{ service.price }}</p>

    <ul v-if="service?.features?.length" class="mt-4 space-y-1 text-sm text-gray-700 list-disc list-inside dark:text-gray-300">
      <li v-for="feature in service.features" :key="feature">{{ feature }}</li>
    </ul>

    <div class="prose max-w-none mt-8">
      <ContentRenderer :value="service" />
    </div>

    <p class="mt-8 text-sm text-gray-600 dark:text-gray-300">
      連絡は <NuxtLink to="/contact" class="text-[#A2A897] hover:underline">Contact</NuxtLink> から。
    </p>
  </article>
</template>

<script setup>
import { serviceCategoryLabel } from '~/siteConfig'

const route = useRoute()

const { data: service } = await useAsyncData(route.path, () => {
  return queryCollection('service').path(route.path).first()
})

if (!service.value) {
  throw createError({
    statusCode: 404,
    message: 'サービスが見つかりません',
  })
}

const categoryLabel = computed(() => serviceCategoryLabel(service.value?.category))

const breadcrumbItems = computed(() => [
  { name: 'Home', path: '/' },
  { name: 'Service', path: '/service' },
  { name: service.value?.title, path: route.path },
])

usePageSeo({
  title: service.value?.title,
  description: service.value?.description,
})

const { serviceJsonLd, breadcrumbJsonLd, injectJsonLd } = useStructuredData()
injectJsonLd(serviceJsonLd(service.value))
injectJsonLd(breadcrumbJsonLd(breadcrumbItems.value))
</script>
