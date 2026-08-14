<template>
  <article class="mx-auto max-w-screen-md px-4 py-10">
    <span class="text-sm font-medium text-violet-800">{{ categoryLabel }}</span>
    <h1 class="mt-2 font-display text-2xl font-bold text-gray-900">{{ service?.title }}</h1>
    <p v-if="service?.price" class="mt-2 text-sm text-gray-500">料金: {{ service.price }}</p>

    <ul v-if="service?.features?.length" class="mt-4 space-y-1 text-sm text-gray-700 list-disc list-inside">
      <li v-for="feature in service.features" :key="feature">{{ feature }}</li>
    </ul>

    <div class="prose max-w-none mt-8">
      <ContentRenderer :value="service" />
    </div>

    <div class="mt-8">
      <UButton to="/contact" color="secondary">
        お問い合わせ
      </UButton>
    </div>
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

useHead({
  title: service.value?.title,
  meta: [
    { key: 'description', name: 'description', content: service.value?.description },
    { key: 'og:title', property: 'og:title', content: service.value?.title },
  ],
})

const { creativeWorkJsonLd, breadcrumbJsonLd, injectJsonLd } = useStructuredData()
injectJsonLd(creativeWorkJsonLd(service.value))
injectJsonLd(
  breadcrumbJsonLd([
    { name: 'Top', path: '/' },
    { name: 'Service', path: '/service' },
    { name: service.value?.title, path: route.path },
  ])
)
</script>
