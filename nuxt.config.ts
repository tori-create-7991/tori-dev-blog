// https://nuxt.com/docs/api/configuration/nuxt-config

import fs from 'node:fs'
import path from 'node:path'
import tailwindcss from '@tailwindcss/vite'
import matter from 'gray-matter'
import { defineNuxtConfig } from 'nuxt/config'

import { sidebarItem, footerItem } from './shared/siteConfig'

export default defineNuxtConfig({
    compatibilityDate: '2026-11-05',
    devtools: { enabled: true },
    ssr: true,
    nitro: {
        preset: 'static',
        static: true,
        // セキュリティヘッダーは firebase.json で配信する（静的出力では routeRules の headers は効かない）
        routeRules: {
            '/**': {
                prerender: true,
                static: true
            }
        },
        prerender: {
            autoSubfolderIndex: false,
            failOnError: false,
            crawlLinks: true,
            routes: [
                ...sidebarItem.map(item => item.to),
                ...footerItem.map(item => item.to),
                '/sitemap.xml',
                '/rss.xml',
                '/robots.txt'
            ]
        },
    },

    hooks: {
        // カテゴリー・タグのページを生成対象に足す。リンクのクロールだけでは、
        // 「Next.js」のように拡張子に見える名前のページが飛ばされるため
        'prerender:routes'(ctx) {
            const postsDir = path.join(process.cwd(), 'content', 'posts')
            for (const file of fs.readdirSync(postsDir).filter(f => f.endsWith('.md'))) {
                const { data } = matter(fs.readFileSync(path.join(postsDir, file), 'utf-8'))
                for (const category of data.categories ?? []) ctx.routes.add(`/category/${category}`)
                for (const tag of data.tags ?? []) ctx.routes.add(`/tag/${tag}`)
            }
        },
    },

    modules: [
        '@nuxt/content',
        '@nuxt/fonts',
        '@nuxt/image',
        '@nuxt/ui',
    ],

    // 旧tori-dev.com(Nuxt2/Vuetify dark theme)の配色に合わせ、ダーク固定にする
    colorMode: {
        preference: 'dark',
        fallback: 'dark',
    },

    image: {
        quality: 80,
        format: ['webp'],
        screens: {
            xs: 320,
            sm: 640,
            md: 768,
            lg: 1024,
            xl: 1280,
            xxl: 1536,
            '2xl': 1536
        },
        presets: {
            default: {
                modifiers: {
                    format: 'webp',
                    quality: 80
                }
            }
        }
    },

    vite: {
        plugins: [tailwindcss()],
    },

    css: ['~/assets/css/main.css'],

    runtimeConfig: {
        public: {
            siteUrl: process.env.NUXT_PUBLIC_SITE_URL || 'https://tori-dev.com',
            // 'production' | 'preview'。preview のときは全ページ noindex にし、
            // robots.txt も全面ブロックにする（本番と同一内容が2ドメインで
            // 索引されるのを防ぐ）
            siteEnv: process.env.NUXT_PUBLIC_SITE_ENV || 'production',
        },
    },
})
