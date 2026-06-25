<template>
  <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-3 xl:grid-cols-3 gap-4">
    <div
      v-for="article in articles"
      :key="article.path"
      class="bg-white rounded-lg shadow-md overflow-hidden"
    >
      <div class="p-4">
        <NuxtLink :to="article.path" class="block">
          <NuxtImg
            v-if="article.image"
            :src="article.image"
            class="w-full h-48 object-cover rounded"
            :placeholder="[50, 25, 75, 5]"
            loading="lazy"
            :alt="article.title"
          />
          <NuxtImg
            v-else
            :src="defaultImage"
            class="w-full h-48 object-cover rounded"
            :placeholder="[50, 25, 75, 5]"
            loading="lazy"
            alt="Default article image"
          />
        </NuxtLink>
        <h3 class="mt-4 text-lg font-semibold">
          <NuxtLink :to="article.path" class="text-blue-600 hover:text-blue-800">
            {{ article.title }}
          </NuxtLink>
        </h3>
        <div class="mt-4 flex items-center">
          <div class="text-gray-600">
            {{ formatDate(article.date) }}
          </div>
          <div class="ml-4 flex flex-wrap gap-2">
            <span
              v-for="tag in article.tags"
              :key="tag"
              class="px-2 py-1 bg-gray-100 text-gray-800 rounded-full text-sm hover:bg-gray-200 cursor-pointer"
              @click="moveTag(tag)"

            >
              {{ tag }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { siteConfig } from "~/siteConfig";
import { useFormatDate } from "~/composables/useFormatDate";
import { useTag } from "~/composables/useTag";

const defaultImage = ref(siteConfig.defaultImage);
const { formatDate } = useFormatDate();
const { moveTag } = useTag();

defineProps({
  articles: {
    type: Array,
    required: true
  }
});





</script>
