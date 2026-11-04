// 全記事のカテゴリーとタグの一覧（重複なし、記事の並び順で最初に出た順）
export const usePostTaxonomy = async () => {
  const { data } = await useAsyncData('post-taxonomy', () =>
    queryCollection('posts').select('tags', 'categories').all(),
  )

  const unique = (key: 'tags' | 'categories') =>
    computed(() => [...new Set((data.value ?? []).flatMap(post => post[key] ?? []))])

  return {
    categories: unique('categories'),
    tags: unique('tags'),
  }
}

export const tagPath = (tag: string) => `/tag/${encodeURIComponent(tag)}`
export const categoryPath = (category: string) => `/category/${encodeURIComponent(category)}`
