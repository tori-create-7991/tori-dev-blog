// https://nuxt.com/docs/api/configuration/nuxt-config

import tailwindcss from '@tailwindcss/vite'
import { defineNuxtConfig } from 'nuxt/config'
import fs from 'fs'
import path from 'path'
import matter from 'gray-matter'

import { sidebarItem, footerItem } from './siteConfig'



export default defineNuxtConfig({
    compatibilityDate: '2024-11-01',
    devtools: { enabled: true },
    ssr: true,
    nitro: {
        preset: 'static',
        static: true,
        routeRules: {
            '/**': {
                cors: true,
                headers: {
                    'Content-Security-Policy': "default-src 'self' https:; style-src 'self' 'unsafe-inline' https:; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; img-src 'self' data: https:; font-src 'self' https:; connect-src 'self' ws: wss: http: https:;",
                    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
                    'X-Content-Type-Options': 'nosniff',
                    'X-Frame-Options': 'DENY',
                    'X-XSS-Protection': '1; mode=block'
                },
                prerender: true,
                static: true
            }
        },
        prerender: {
            autoSubfolderIndex: false,
            failOnError: false,
            routes: [
                ...sidebarItem.map(item => item.to),
                ...footerItem.map(item => item.to),
                '/sitemap.xml',
                '/rss.xml'
            ]
        },

    },

    hooks: {
        async 'prerender:routes'(ctx) {
            // 投稿データを取得
            const postsDir = path.join(process.cwd(), 'content', 'posts')
            const files = fs.readdirSync(postsDir)
            const posts = files
                .filter(file => file.endsWith('.md'))
                .map(file => {
                    const content = fs.readFileSync(path.join(postsDir, file), 'utf-8')
                    const { data } = matter(content)
                    return data
                })

            // カテゴリーとタグのルートを追加
            if (posts) {
                const categories = new Set<string>()
                const tags = new Set<string>()

                // 投稿からカテゴリーとタグを収集
                posts.forEach((post: { categories?: string[], tags?: string[] }) => {
                    if (post.categories) {
                        post.categories.forEach((category: string) => {
                            categories.add(category)
                        })
                    }
                    if (post.tags) {
                        post.tags.forEach((tag: string) => {
                            tags.add(tag)
                        })
                    }
                })

                // カテゴリーページのルートを追加
                categories.forEach((category) => {
                    ctx.routes.add(`/category/${category}`)
                })

                // タグページのルートを追加
                tags.forEach((tag) => {
                    ctx.routes.add(`/tag/${tag}`)
                })
            }
        }
    },

    modules: [
        '@nuxt/content',
        '@nuxt/eslint',
        '@nuxt/fonts',
        '@nuxt/image',
        '@nuxt/ui',
        '@pinia/nuxt',
    ],

    image: {
    //     provider: 'ipxStatic',
    //     ipxStatic: {
    //         baseURL: '/',
    //         dir: 'public',
    //         maxAge: 60 * 60 * 24 * 7 // 7 days
    //     },
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
        build: {
            sourcemap: true,
            cssCodeSplit: true
        },
        css: {
            devSourcemap: true
        }
    },


    css: ['~/assets/css/main.css'],

    content: {
        // 基本的なコンテンツ設定
    },

    dir: {
        public: process.env.NODE_ENV === 'production' ? 'public' : 'public_dev'
    },

    runtimeConfig: {
        public: {
            siteUrl: process.env.NUXT_PUBLIC_SITE_URL || 'https://tori-dev.com',
        },
    },


    // // Add static file handling configuration
    // routeRules: {
    //     '/images/**': { static: true }
    // }
})
