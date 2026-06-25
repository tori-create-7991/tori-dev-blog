import { defineStore } from 'pinia'

export const useStore = defineStore('main', {
  state: () => ({
    tag: '',
    tags: [] as string[],
    toc: null as any,
    category: '',
    categories: [] as string[],
    contents: [] as any,
    categoryPost: {} as any,
    tagPost: {} as any,
    microcmsPost: {} as any,
    announcementsPost: {} as any,
  }),

  actions: {
    createToc(toc: any) {
      this.toc = toc
    },
    setTag(searchtag: string) {
      this.tag = searchtag
    },
    setTags(tags: string[]) {
      this.tags = tags
    },
    setContents(content: any) {
      this.contents = content
    },
    setCategoryPost(post: any) {
      this.categoryPost = post
    },
    setTagPost(post: any) {
      this.tagPost = post
    },
    setCategories(categories: string[]) {
      this.categories = categories
    },
    setCategory(category: string) {
      this.category = category
    },
    setAnnouncementsPost(announcementsPost: any) {
      this.announcementsPost = announcementsPost
    },
  },

  getters: {
    getContents: (state) => state.contents,
    getCategoryPost: (state) => state.categoryPost,
    getTagPost: (state) => state.tagPost,
    getAnnouncementsPost: (state) => state.announcementsPost,
    getTag: (state) => state.tag,
    getCategory: (state) => state.category,
  },
})
