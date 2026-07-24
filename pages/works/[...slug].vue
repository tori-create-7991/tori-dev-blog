<template>
  <article class="mx-auto max-w-screen-md px-4 py-10">
    <span class="text-sm font-medium text-violet-800">{{ categoryLabel }}</span>
    <h1 class="mt-2 font-display text-2xl font-bold text-gray-900">{{ work?.title }}</h1>

    <div class="mt-3 flex flex-wrap gap-3 text-sm text-gray-500">
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

const categoryLabels = {
  'ax-dx': 'AX・DX',
  training: '研修',
  development: '開発',
}
const categoryLabel = computed(() => categoryLabels[work.value?.category] || work.value?.category)

useHead({
  title: work.value?.title,
  meta: [
    { hid: 'description', name: 'description', content: work.value?.description },
    { hid: 'og:title', property: 'og:title', content: work.value?.title },
  ],
})
</script>
