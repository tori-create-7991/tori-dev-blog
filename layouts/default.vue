<template>
  <div class="min-h-screen flex flex-col">
    <!-- WCAG 2.2 SC 2.4.1 (Level A) Bypass Blocks。フォーカス時のみ表示する -->
    <a
      href="#main"
      class="sr-only focus:not-sr-only focus:absolute focus:z-50 focus:top-2 focus:left-2 focus:rounded-md focus:bg-[#272727] focus:px-4 focus:py-2 focus:text-white focus:outline focus:outline-2 focus:outline-offset-2 focus:outline-[#A2A897]"
    >
      本文へスキップ
    </a>
    <AppHeader />
    <main id="main" class="flex-grow container mx-auto px-4 py-8">
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

/* 日本語本文の可読性（デジタル庁デザインシステム準拠）
   - 本文 16px 以上 / 行高 1.7 / 1行あたり全角40字前後
   - 見出しは文節で折り返す（対応ブラウザのみ） */
body {
  line-height: 1.7;
  line-break: strict;
  /* anywhere は min-content 幅に影響してボタン等の flex アイテムを潰すため使わない。
     break-word は既存の折り返し計算を変えずに長い URL だけを折る */
  overflow-wrap: break-word;
}

h1, h2, h3, h4 {
  word-break: auto-phrase;
  text-wrap: balance;
  line-height: 1.4;
}

.prose {
  line-height: 1.8;
}
</style>
