<template>
  <section class="pb-12">
    <section class="relative">
      <div class="w-full h-[50vh] relative">
        <nuxt-img
          :src="heroImage"
          class="absolute inset-0 w-full h-full object-cover"
          :modifiers="{ format: 'webp', quality: 80 }"
          alt="Hero background"
        />
        <div class="flex items-center justify-center h-full relative z-10">
          <div class="text-center text-white">
            <p class="text-2xl font-bold">{{ siteConfig.welcomeMessage }}</p>
          </div>
        </div>
      </div>
    </section>
  </section>
</template>

<script setup>
import { siteConfig } from '~/siteConfig'
const heroImage = '/default.jpg'
</script>

<style>
.home {
  padding-bottom: 50px;
}

.home-hero__content {
  background-size: cover;
  background-position: center center;
  width: 100%;
  height: 50vh;
}

.home-hero__content-text {
  color: white;
  text-align: center;
  font-size: 28px;
  font-weight: bold;
}
</style>
