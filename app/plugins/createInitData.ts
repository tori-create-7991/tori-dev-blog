import { useStore } from '~/stores/store'


export default defineNuxtPlugin(async () => {
    const store = useStore()
    const { data: posts } = await useAsyncData('posts', async () =>
        await queryCollection('posts').all()
    )

    const categories: string[] = []
    const tags: string[] = []

    posts.value?.forEach((post) => {
        if (post.categories) {
            categories.push(...post.categories)
        }
        if (post.tags) {
            post.tags.forEach((tag: string) => {
                tags.push(tag)
            })
        }
    })

    const uniqueCategories = [...new Set(categories)]
    const uniqueTags = [...new Set(tags)]

    store.setCategories(uniqueCategories)
    store.setTags(uniqueTags)
    store.setContents(posts.value)
})
