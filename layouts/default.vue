<template>
  <div class="min-h-screen flex flex-col">
    <AppHeader />
    <main class="flex-grow container mx-auto px-4 py-8">
      <NuxtPage />
    </main>
    <AppFooter />
  </div>
</template>

<script setup>
import AppHeader from "../components/AppHeader.vue";
import AppFooter from "../components/AppFooter.vue";


</script>

<style>
html * {
  box-sizing: border-box;
}

html #app a {
  text-decoration-line: none;
  color: #9e9e9e;
}
</style>
