<template>
  <UApp>
    <NuxtLayout>
      <NuxtPage />
    </NuxtLayout>
  </UApp>
</template>

<script setup>
import { siteConfig } from '~/siteConfig'

useHead({
  htmlAttrs: {
    lang: siteConfig.lang
  },
  title: siteConfig.siteTitle,
  meta: [
    { charset: 'utf-8' },
    { name: 'viewport', content: 'width=device-width, initial-scale=1' },
    { hid: 'description', name: 'description', content: siteConfig.description }
  ]
})
</script>
