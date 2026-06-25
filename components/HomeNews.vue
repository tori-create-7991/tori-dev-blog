<template>
  <div class="mt-8 mb-8">
    <h2 class="text-2xl font-bold">お知らせ</h2>
    <ul class="mt-8">
      <li
        v-for="post in announcementsPosts"
        :key="post.slug"
        class="flex items-start"
      >
        <p class="text-gray-600">{{ formatDate(post.date) }}</p>
        <h3 class="ml-8">
          <NuxtLink :to="`${post.path}`" class="text-blue-600 hover:text-blue-800">
            {{ post.title }}
          </NuxtLink>
        </h3>
      </li>
    </ul>
  </div>
</template>

<script setup>
import { useStore } from '~/stores/store';
import { useFormatDate } from "~/composables/useFormatDate";

const store = useStore();
const { formatDate } = useFormatDate()
const announcementsPosts = computed(() => store.getAnnouncementsPost );
</script>
