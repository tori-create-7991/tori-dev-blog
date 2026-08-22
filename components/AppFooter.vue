<template>
  <footer class="border-t border-gray-200 bg-white py-10 dark:border-[#333333] dark:bg-[#121212]">
    <div class="mx-auto max-w-screen-xl px-4">
      <!-- 第二のサイトマップ: 全セクションへの導線をフッターにも持たせる -->
      <div class="grid grid-cols-2 gap-8 sm:grid-cols-4">
        <nav aria-label="フッターナビゲーション">
          <h2 class="mb-3 text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
            サイト内
          </h2>
          <ul class="space-y-2">
            <li v-for="item in mainItems" :key="item.to">
              <NuxtLink
                :to="item.to"
                class="text-sm text-gray-600 transition-colors hover:text-[#A2A897] dark:text-gray-300 dark:hover:text-[#A2A897]"
              >
                {{ item.title }}
              </NuxtLink>
            </li>
          </ul>
        </nav>

        <nav aria-label="規約・問い合わせ">
          <h2 class="mb-3 text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
            その他
          </h2>
          <ul class="space-y-2">
            <li v-for="item in footerItem" :key="item.to">
              <NuxtLink
                :to="item.to"
                class="text-sm text-gray-600 transition-colors hover:text-[#A2A897] dark:text-gray-300 dark:hover:text-[#A2A897]"
              >
                {{ item.title }}
              </NuxtLink>
            </li>
          </ul>
        </nav>

        <div v-if="socials.length">
          <h2 class="mb-3 text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
            外部プロフィール
          </h2>
          <ul class="space-y-2">
            <!-- rel="me" は分散型の本人確認に使われる。JSON-LD の sameAs と同じ URL 群を出す -->
            <li v-for="profile in socials" :key="profile.key">
              <a
                :href="profile.url"
                rel="me noopener"
                target="_blank"
                class="text-sm text-gray-600 transition-colors hover:text-[#A2A897] dark:text-gray-300 dark:hover:text-[#A2A897]"
              >
                {{ profile.label }}
              </a>
            </li>
          </ul>
        </div>

        <div>
          <h2 class="mb-3 text-xs font-semibold uppercase tracking-wider text-gray-500 dark:text-gray-400">
            購読
          </h2>
          <ul class="space-y-2">
            <li>
              <a
                href="/rss.xml"
                class="text-sm text-gray-600 transition-colors hover:text-[#A2A897] dark:text-gray-300 dark:hover:text-[#A2A897]"
              >
                RSS
              </a>
            </li>
          </ul>
        </div>
      </div>

      <p class="mt-10 text-sm text-gray-500 dark:text-gray-400">
        &copy; {{ new Date().getFullYear() }} Tori All Rights Reserved.
      </p>
    </div>
  </footer>
</template>

<script setup>
import { footerItem, sidebarItem, secondaryItem, feedPublished, activeSocialProfiles } from "~/siteConfig";

// つぶやき(Feed)は公開フラグが立っているときだけフッターに出す
const mainItems = computed(() => [
  ...sidebarItem,
  ...(feedPublished ? secondaryItem : []),
]);

const socials = activeSocialProfiles();
</script>
