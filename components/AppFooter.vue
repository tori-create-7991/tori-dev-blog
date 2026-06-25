<template>
  <footer class="bg-white shadow-md py-4">
    <div class="container mx-auto px-4">
      <div class="flex flex-col md:flex-row items-center justify-between space-y-2 md:space-y-0">
        <span class="text-gray-600">
          &copy; {{ new Date().getFullYear() }} Tori All Rights Reserved.
        </span>
        <div class="flex flex-col md:flex-row space-y-2 md:space-y-0 md:space-x-4">
          <NuxtLink
            v-for="item in footerItem"
            :key="item"
            :to="item.to"
            class="text-gray-600 hover:text-gray-900 transition-colors duration-200"
          >
            {{ item.title }}
          </NuxtLink>
        </div>
      </div>
    </div>
  </footer>
</template>

<script>
import { footerItem } from "../siteConfig";

export default {
  data() {
    return {
      footerItem: footerItem,
    };
  },
};
</script>

<style>
.footerItems {
  display: flex;
  flex-direction: row;
}
.footerItems > * {
  margin-left: 3px;
}

/* 画面幅が768px以下の場合のスタイル */
@media (max-width: 768px) {
  .footerItems {
    flex-direction: column; /* 縦並びに変更 */
    align-items: flex-start;
  }

  .footerItems > * {
    padding-left: 0; /* 余白を調整 */
    padding-top: 3px; /* アイテム間のスペースを追加 */
  }
}
</style>
