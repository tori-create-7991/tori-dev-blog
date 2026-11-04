<template>
  <nav aria-label="パンくず" class="mb-4 text-sm">
    <ol class="flex flex-wrap items-center gap-1 text-gray-500 dark:text-gray-400">
      <li v-for="(item, index) in items" :key="item.path" class="flex items-center gap-1">
        <NuxtLink
          v-if="index < items.length - 1"
          :to="item.path"
          class="hover:text-[#A2A897] hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#A2A897] rounded"
        >
          {{ item.name }}
        </NuxtLink>
        <!-- 現在地はリンクにしない（NN/g のパンくずガイドライン） -->
        <span v-else aria-current="page" class="text-gray-700 dark:text-gray-200 line-clamp-1">
          {{ item.name }}
        </span>
        <span v-if="index < items.length - 1" aria-hidden="true" class="px-1 text-gray-300 dark:text-gray-600">/</span>
      </li>
    </ol>
  </nav>
</template>

<script setup>
defineProps({
  items: {
    type: Array,
    required: true,
  },
})
</script>
