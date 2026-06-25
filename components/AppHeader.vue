<template>
    <header class="bg-white">
        <!-- Navigation Drawer -->
        <div class="fixed inset-0 z-40" v-if="drawer">
            <div
                class="fixed inset-0 bg-gray-600 bg-opacity-75 transition-opacity duration-300 ease-in-out"
                @click="drawer = false"
            ></div>
            <div
                class="fixed inset-y-0 left-0 flex flex-col w-64 bg-white transform transition-transform duration-300 ease-in-out"
            >
                <div class="flex-1 flex flex-col pt-5 pb-4 overflow-y-auto">
                    <div class="flex items-center justify-between px-4">
                        <button
                            @click="drawer = false"
                            class="p-2 rounded-md text-gray-400 hover:text-gray-500 hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-green-500"
                        >
                            <span class="sr-only">Close menu</span>
                            <svg
                                class="h-6 w-6"
                                xmlns="http://www.w3.org/2000/svg"
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                            >
                                <path
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    stroke-width="2"
                                    d="M6 18L18 6M6 6l12 12"
                                />
                            </svg>
                        </button>
                    </div>
                    <nav class="mt-5 flex-1 px-2 space-y-1">
                        <NuxtLink
                            v-for="item in items"
                            :key="item"
                            :to="item.to"
                            class="group flex items-center px-2 py-2 text-base font-medium rounded-md text-gray-600 hover:bg-gray-50 transition-colors duration-200"
                        >
                            <span class="text-gray-700">{{ item.title }}</span>
                        </NuxtLink>
                        <NuxtLink
                            to="/tag"
                            class="group flex items-center px-2 py-2 text-base font-medium rounded-md text-gray-600 hover:bg-gray-50 transition-colors duration-200"
                        >
                            <span class="text-gray-700">{{ tagName }}</span>
                        </NuxtLink>
                        <div class="space-y-1">
                            <button
                                @click="isCategoryOpen = !isCategoryOpen"
                                class="w-full flex items-center justify-between px-2 py-2 text-base font-medium text-gray-700 hover:bg-gray-50 rounded-md"
                            >
                                <span>Category</span>
                                <svg
                                    class="h-5 w-5 transform transition-transform"
                                    :class="{ 'rotate-180': isCategoryOpen }"
                                    xmlns="http://www.w3.org/2000/svg"
                                    viewBox="0 0 20 20"
                                    fill="currentColor"
                                >
                                    <path
                                        fill-rule="evenodd"
                                        d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z"
                                        clip-rule="evenodd"
                                    />
                                </svg>
                            </button>
                            <div v-show="isCategoryOpen" class="pl-2 space-y-1">
                                <NuxtLink
                                    v-for="category in categories"
                                    :key="category"
                                    class="group flex items-center px-2 py-2 text-base font-medium rounded-md text-gray-600 hover:bg-gray-50 transition-colors duration-200"
                                    @click.prevent="moveCategory(category)"
                                >
                                    <span class="text-gray-700">{{
                                        category
                                    }}</span>
                                </NuxtLink>
                            </div>
                        </div>
                    </nav>
                </div>
            </div>
        </div>

        <!-- Navigation Bar -->
        <div class="app-header-bar">
            <button
                class="px-4 border-r border-gray-200 text-gray-500 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-green-500"
                @click="drawer = !drawer"
            >
                <span class="sr-only">Open menu</span>
                <svg
                    class="h-6 w-6"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                >
                    <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M4 6h16M4 12h16M4 18h16"
                    />
                </svg>
            </button>
            <div class="flex-1 px-4 flex justify-between">
                <div class="flex-1 flex">
                    <h1
                        class="text-xl font-bold text-gray-700 cursor-pointer"
                        @click="$router.push('/')"
                    >
                        {{ toolbarTitle }}
                    </h1>
                </div>
                <div class="ml-4 flex items-center md:ml-6">
                    <NuxtLink
                        :to="advisoryPath"
                        class="advisory-cta hidden sm:inline-flex items-center px-3 py-1.5 mr-3 rounded-full text-sm font-semibold text-white bg-green-600 hover:bg-green-700 transition-colors"
                    >
                        {{ advisoryCtaLabel }}
                    </NuxtLink>
                    <div class="flex space-x-4">
                        <a
                            v-if="twitterUrl"
                            :href="twitterUrl"
                            target="_blank"
                            class="text-gray-400 hover:text-gray-500"
                        >
                            <i class="fab fa-twitter text-xl"></i>
                        </a>
                        <a
                            v-if="facebookUrl"
                            :href="facebookUrl"
                            target="_blank"
                            class="text-gray-400 hover:text-gray-500"
                        >
                            <i class="fab fa-facebook text-xl"></i>
                        </a>
                        <a
                            v-if="instagramUrl"
                            :href="instagramUrl"
                            target="_blank"
                            class="text-gray-400 hover:text-gray-500"
                        >
                            <i class="fab fa-instagram text-xl"></i>
                        </a>
                    </div>
                    <button
                        v-if="toc && !permanent"
                        @click="drawerRight = !drawerRight"
                        class="ml-4 p-1 rounded-full text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                    >
                        <span class="sr-only">View table of contents</span>
                        <svg
                            class="h-6 w-6"
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M4 6h16M4 12h16M4 18h16"
                            />
                        </svg>
                    </button>
                </div>
            </div>
        </div>

        <!-- Table of Contents -->
        <div
            v-if="toc"
            class="toc-sidebar"
            :class="{
                'translate-x-0': drawerRight,
                'translate-x-full': !drawerRight,
            }"
        >
            <div class="flex-1 flex flex-col pt-5 pb-4 overflow-y-auto">
                <div class="flex items-center flex-shrink-0 px-4">
                    <h3 class="text-lg font-medium text-gray-700">目次</h3>
                </div>
                <nav class="mt-5 flex-1 px-2 space-y-1 overflow-y-auto pb-20">
                    <a
                        v-for="link of toc"
                        :key="link.id"
                        :href="`#${link.id}`"
                        class="group flex items-center px-2 py-2 text-sm font-medium rounded-md text-gray-600 hover:bg-gray-50"
                        :class="{
                            'pl-4': link.depth === 2,
                            'pl-8': link.depth === 3,
                        }"
                    >
                        <span class="text-gray-700">{{ link.text }}</span>
                    </a>
                </nav>
            </div>
        </div>
    </header>
</template>

<script setup>
import { siteConfig, sidebarItem } from '~/siteConfig'
import { useStore } from '~/stores/store'
import { useRoute } from 'vue-router'

const { moveCategory } = useCategory();

const store = useStore()
const categories = computed(() => store.categories)
const toc = computed(() => store.toc)

const items = sidebarItem
const tagName = 'Tag'
const toolbarTitle = siteConfig.siteTitle
const drawer = ref(false)
const drawerRight = ref(false)
const permanent = ref(false)
const isCategoryOpen = ref(false)
const twitterUrl = siteConfig.twitterUrl
const facebookUrl = siteConfig.facebookUrl
const instagramUrl = siteConfig.instagramUrl
const advisoryPath = siteConfig.advisoryPath
const advisoryCtaLabel = siteConfig.advisoryCtaLabel


// Watch for route changes to close the drawer
const route = useRoute()
watch(
    () => route.path,
    () => {
        drawer.value = false
    }
)
</script>

<style scoped>
.link-icons {
    color: #9e9e9e;
    margin: 0 8px;
}

.app-header-bar {
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    z-index: 1000;
    height: 4rem; /* h-16 = 64px */
    background: #f0fdf4; /* bg-green-100相当 */
    display: flex;
    align-items: center;
}

/* 下のコンテンツが隠れないようにheader下に余白 */
header {
    padding-top: 4rem;
}

.toc-sidebar {
    position: fixed;
    top: 0; /* トップバーの高さ分下げる→0に変更して境目をなくす */
    right: 0;
    width: 16rem; /* w-64 */
    max-height: calc(
        100vh - 4rem - 64px + 4rem
    ); /* topを0にした分だけ高さを補正 */
    background: #fff;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
    z-index: 900;
    overflow-y: auto;
    transition: transform 0.2s;
    border-top-left-radius: 0;
    border-top-right-radius: 0;
}

@media (max-width: 1024px) {
    .toc-sidebar {
        width: 100vw;
        left: 0;
        right: 0;
        max-width: 100vw;
    }
}
</style>
