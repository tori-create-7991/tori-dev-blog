<template>
    <header class="sticky top-0 z-40 bg-white/90 backdrop-blur border-b border-gray-200 dark:bg-[#121212]/95 dark:border-[#333333]">
        <div class="mx-auto flex h-16 max-w-screen-xl items-center justify-between px-4">
            <NuxtLink to="/" class="font-display text-lg font-bold text-gray-900 dark:text-white">
                {{ toolbarTitle }}
            </NuxtLink>

            <nav class="hidden md:flex items-center gap-6" aria-label="メインナビゲーション">
                <NuxtLink
                    v-for="item in navItems"
                    :key="item.to"
                    :to="item.to"
                    class="group flex flex-col items-center leading-tight text-gray-700 hover:text-[#A2A897] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#A2A897] rounded dark:text-gray-200 dark:hover:text-[#A2A897]"
                >
                    <span class="text-sm font-medium">{{ item.label }}</span>
                    <span class="text-[10px] uppercase tracking-wider text-gray-400 dark:text-gray-500">{{ item.en }}</span>
                </NuxtLink>
            </nav>

            <div class="flex items-center gap-3">
                <button
                    class="md:hidden p-2 text-gray-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#A2A897] rounded-md dark:text-gray-300"
                    :aria-label="mobileMenuOpen ? 'メニューを閉じる' : 'メニューを開く'"
                    :aria-expanded="mobileMenuOpen"
                    aria-controls="mobile-menu"
                    @click="mobileMenuOpen = !mobileMenuOpen"
                >
                    <svg v-if="!mobileMenuOpen" class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
                    </svg>
                    <svg v-else class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                </button>
            </div>
        </div>

        <div id="mobile-menu" v-if="mobileMenuOpen" class="md:hidden border-t border-gray-200 bg-white dark:bg-[#121212] dark:border-[#333333]">
            <nav class="flex flex-col gap-1 p-4" aria-label="モバイルナビゲーション">
                <NuxtLink
                    v-for="item in navItems"
                    :key="item.to"
                    :to="item.to"
                    class="rounded-md px-3 py-2 text-base font-medium text-gray-700 hover:bg-gray-50 dark:text-gray-200 dark:hover:bg-[#272727]"
                    @click="mobileMenuOpen = false"
                >
                    {{ item.label }}
                    <span class="ml-2 text-xs uppercase tracking-wider text-gray-400 dark:text-gray-500">{{ item.en }}</span>
                </NuxtLink>
            </nav>
        </div>
    </header>
</template>

<script setup>
import { siteConfig, sidebarItem } from '~/siteConfig'
import { useRoute } from 'vue-router'

const toolbarTitle = siteConfig.siteTitle
const mobileMenuOpen = ref(false)

// ラベルは日本語を主、英語を補助表示にする（読者は中小企業の非エンジニア意思決定者）
const navItems = sidebarItem.map((item) => ({
    label: item.title,
    en: item.en,
    to: item.to,
}))

const route = useRoute()
watch(
    () => route.path,
    () => {
        mobileMenuOpen.value = false
    }
)
</script>
