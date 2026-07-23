// 旧ブログ(012_nuxt-01_toriblog_vuetify, Nuxt2/Vuetify)の記事をtori-dev-blogのcontent/posts/へ移行する一回限りのユーティリティ。
// 旧frontmatterの区切り行が `--- `(末尾スペース付き)で統一されていないため、正規表現ではなくgray-matterでパースする。
import fs from 'fs'
import path from 'path'
import matter from 'gray-matter'

const sourceDir =
  process.argv[2] ??
  path.join(
    process.env.HOME ?? '',
    'Repo/my/012/012_nuxt-01_toriblog_vuetify/toriblog/content/post'
  )
const destDir = './content/posts'

if (!fs.existsSync(sourceDir)) {
  throw new Error(`旧ブログのソースディレクトリが見つかりません: ${sourceDir}`)
}

fs.mkdirSync(destDir, { recursive: true })

const files = fs.readdirSync(sourceDir).filter((f) => f.endsWith('.md'))

for (const file of files) {
  const raw = fs.readFileSync(path.join(sourceDir, file), 'utf-8')
  const parsed = matter(raw)
  const data = parsed.data
  const content = parsed.content

  const newData = {
    title: data.title,
    description: '',
    date: data.date,
    image: data.image ?? '',
    tags: data.tags ?? [],
    categories: data.category ?? [],
  }

  const output = matter.stringify(content, newData)
  fs.writeFileSync(path.join(destDir, file), output)
  console.log(`migrated: ${file}`)
}

console.log(`${files.length}件の記事を${destDir}へ移行しました`)
