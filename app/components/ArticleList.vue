<template>
  <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-3 xl:grid-cols-3 gap-4">
    <article
      v-for="article in articles"
      :key="article.path"
      class="bg-white rounded-lg shadow-md overflow-hidden dark:bg-[#121212] dark:border dark:border-[#333333]"
    >
      <div class="p-4">
        <!-- サムネイルは装飾。tabindex=-1 で見出しリンクとタブ順が二重にならないようにする -->
        <NuxtLink :to="article.path" tabindex="-1" aria-hidden="true" class="block">
          <NuxtImg
            v-if="article.image"
            :src="article.image"
            class="w-full h-48 object-cover rounded"
            format="webp"
            width="400"
            height="192"
            sizes="sm:100vw md:50vw lg:400px"
            :placeholder="[50, 25, 75, 5]"
            loading="lazy"
            :alt="article.title"
          />
          <!-- アイキャッチ画像が無い記事は、タイトルとパスから CSS だけで生成する -->
          <ArticleThumb v-else :title="article.title" :path="article.path" />
        </NuxtLink>
        <h3 class="mt-4 text-lg font-semibold">
          <NuxtLink :to="article.path" class="text-[#A2A897] hover:text-[#8b9179]">
            {{ article.title }}
          </NuxtLink>
        </h3>
        <div class="mt-4 flex flex-wrap items-center gap-x-4 gap-y-2">
          <time :datetime="isoDate(article.date)" class="text-gray-600 dark:text-gray-300">
            {{ formatDate(article.date) }}
          </time>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="tag in article.tags"
              :key="tag"
              type="button"
              class="px-2 py-1 bg-gray-100 text-gray-800 rounded-full text-sm hover:bg-gray-200 cursor-pointer dark:bg-gray-800 dark:text-gray-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#A2A897]"
              @click="moveTag(tag)"
            >
              {{ tag }}
            </button>
          </div>
        </div>
      </div>
    </article>
  </div>
</template>

<script setup>
import { useFormatDate } from "~/composables/useFormatDate";
import { useTag } from "~/composables/useTag";

const { formatDate } = useFormatDate();
const { moveTag } = useTag();

// <time datetime> は ISO 8601 で出す
const isoDate = (value) => {
  if (!value) return undefined;
  const d = value instanceof Date ? value : new Date(value);
  return Number.isNaN(d.getTime()) ? undefined : d.toISOString();
};

defineProps({
  articles: {
    type: Array,
    required: true
  }
});
</script>
