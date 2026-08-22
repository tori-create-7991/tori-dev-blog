<template>
    <header class="sticky top-0 z-40 bg-white/90 backdrop-blur border-b border-gray-200 dark:border-gray-700 dark:bg-[#121212]/90">
        <div class="mx-auto flex h-16 max-w-screen-xl items-center justify-between px-4">
            <NuxtLink to="/" class="font-display text-lg font-bold text-gray-900 dark:text-white">
                {{ toolbarTitle }}
            </NuxtLink>

            <nav class="hidden md:flex items-center gap-6">
                <NuxtLink
                    v-for="item in navItems"
                    :key="item.to"
                    :to="item.to"
                    class="text-sm font-medium text-gray-700 hover:text-[#A2A897] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#A2A897] rounded dark:text-gray-300"
                >
                    {{ item.label }}
                </NuxtLink>
            </nav>

            <div class="flex items-center gap-3">
                <button
                    class="md:hidden p-2 text-gray-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#A2A897] rounded-md dark:text-gray-400"
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

        <div id="mobile-menu" v-if="mobileMenuOpen" class="md:hidden border-t border-gray-200 bg-white dark:border-gray-700 dark:bg-[#121212]">
            <nav class="flex flex-col gap-1 p-4">
                <NuxtLink
                    v-for="item in navItems"
                    :key="item.to"
                    :to="item.to"
                    class="rounded-md px-3 py-2 text-base font-medium text-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800 dark:text-gray-300"
                    @click="mobileMenuOpen = false"
                >
                    {{ item.label }}
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

const navItems = sidebarItem.map((item) => ({
    label: item.title,
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
