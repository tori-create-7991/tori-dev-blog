// https://www.npmjs.com/package/notion-to-md
import { NotionToMarkdown } from 'notion-to-md'
import { Client } from '@notionhq/client'
import fs from 'fs'
import type { PageObjectResponse } from '@notionhq/client'
import path from 'path'
import https from 'https'
import dotenv from 'dotenv'

// Load environment variables from .env file
dotenv.config()

const apiKey = process.env.NOTION_API_KEY
const databaseId = process.env.NOTION_DATABASE_ID

if (!apiKey || !databaseId) {
    throw new Error('Notion API settings are not set in environment variables')
}

const writePath = './content/posts'
const publicImagesPath = './public/images'

// Ensure public/images directory exists
if (!fs.existsSync(publicImagesPath)) {
    fs.mkdirSync(publicImagesPath, { recursive: true })
}

const notion = new Client({
    auth: apiKey,
})

// passing notion client to the option
const n2m = new NotionToMarkdown({
    notionClient: notion,
    config: {
        separateChildPage: true, // default: false
    },
})

// Function to download image from URL
const downloadImage = (url: string, filename: string): Promise<string> => {
    return new Promise((resolve, reject) => {
        const filepath = path.join(publicImagesPath, filename)
        const localUrl = `/images/${filename}`

        // ファイルが既に存在する場合は、そのパスを返す
        if (fs.existsSync(filepath)) {
            console.log('File already exists:', {
                originalUrl: url,
                localUrl: localUrl
            })
            resolve(localUrl)
            return
        }

        const file = fs.createWriteStream(filepath)
        https.get(url, (response) => {
            response.pipe(file)
            file.on('finish', () => {
                file.close()
                console.log('File downloaded successfully:', {
                    originalUrl: url,
                    localUrl: localUrl
                })
                resolve(localUrl)
            })
        }).on('error', (err) => {
            fs.unlink(filepath, () => {})
            console.error('Error downloading file:', {
                originalUrl: url,
                localUrl: localUrl,
                error: err.message
            })
            reject(err)
        })
    })
}

// Function to get filename from URL
const getFilenameFromUrl = (url: string): string => {
    try {
        const urlObj = new URL(url)
        const pathname = urlObj.pathname
        const filename = pathname.split('/').pop() || `notion-image-${Date.now()}.jpg`
        // ファイル名に拡張子がない場合は.jpgを追加
        return filename.includes('.') ? filename : `${filename}.jpg`
    } catch {
        return `notion-image-${Date.now()}.jpg`
    }
}

// google photoの場合だが一旦コメントアウト
n2m.setCustomTransformer('embed', async (block) => {
    const { embed } = block as any
    if (embed?.url?.includes('https://drive.google.com')) {
        //https://drive.google.com/file/d/1xqJyI84Q3khdjH7fFo8E0wF4wSmvilWR/view?usp=sharing
        const id = embed.url.split('d/')[1].split('/')[0]
        // 一旦iframeにする
        return `</br><iframe
  src="https://drive.google.com/viewer?srcid=${id}&pid=explorer&efh=false&a=v&chrome=false&embedded=true"
  style="width:300px; height:300px;"
  frameborder="0"></iframe></br>` // some special rendering
    }
        return embed // use default behavior


})

// n2m.setCustomTransformer('image', async (block) => {
//     const { image } = block as any
//     if (image?.type === 'external' && image.external?.url) {
//         const filename = getFilenameFromUrl(image.external.url)
//         try {
//             const imagePath = await downloadImage(image.external.url, filename)
//             // マークダウン形式でローカルパスを返す
//             return `![${filename}](${imagePath})`
//         } catch (error) {
//             console.error('Error downloading image:', error)
//             return `![${filename}](${image.external.url})`
//         }
//     }
//     return ''
// })

;(async () => {
    try {
        const pageList = await notion.databases.query({
            database_id: databaseId,
            filter: {
                property: 'Published',
                checkbox: {
                    equals: true
                }
            }
        })

        for (const iterator of pageList.results) {
            const res = iterator as PageObjectResponse
            console.log(res.properties)

            const title =
                res.properties.title.type === 'rich_text' &&
                res.properties.title.rich_text[0]
                    ? res.properties.title.rich_text[0].plain_text
                    : ''
            const slug =
                res.properties.slug.type === 'rich_text' &&
                res.properties.slug.rich_text[0]
                    ? res.properties.slug.rich_text[0].plain_text
                    : ''
            const category =
                res.properties.category.type === 'select' &&
                res.properties.category.select
                    ? res.properties.category.select.name
                    : ''
            const tags =
                res.properties.tags.type === 'multi_select' &&
                res.properties.tags.multi_select
                    ? res.properties.tags.multi_select.map((data) => {
                          return data.name
                      })
                    : []
            const mdTags = tags.reduce(function (previousValue, currentValue) {
                return previousValue + ' - ' + currentValue + '\n'
            }, '')

            const date =
                res.properties.createdAt.type === 'date' &&
                res.properties.createdAt.date
                    ? res.properties.createdAt.date.start
                    : ''

            const updateDate =
                res.properties.updateDate.type === 'date' &&
                res.properties.updateDate.date
                    ? res.properties.updateDate.date.start
                    : ''

            const iconImage =
                res.properties.image.type === 'files' &&
                res.properties.image.files[0]
                    ? res.properties.image.files[0]?.name
                    : ''

            const mdHeader = `--- \n title: ${title} \n updateDate: ${updateDate} \n date: ${date}\n categories: \n - ${category} \n tags: \n${mdTags} \n image: ${iconImage}  \n---\n\n `

            const mdblocks = await n2m.pageToMarkdown(res.id)
            // console.log('mdblocks', mdblocks)

            const mdString = n2m.toMarkdownString(mdblocks)
            // console.log('mdString', mdString)

            // undefinedを改行に変換し、画像のダウンロードを処理
            const mdData = await (async () => {
                let content = mdString?.parent?.replace(/undefined/g, '<br>\n') || ''

                // 画像のダウンロードを処理
                const imageRegex = /!\[(.*?)\]\((.*?)\)/g
                const matches = [...content.matchAll(imageRegex)]

                for (const match of matches) {
                    const [fullMatch, alt, url] = match
                    if (url.startsWith('https://prod-files-secure')) {
                        try {
                            const filename = getFilenameFromUrl(url)
                            await downloadImage(url, filename)
                            content = content.replace(fullMatch, `![${alt}](/images/${filename})`)
                        } catch (error) {
                            console.error(`Error downloading image ${url}:`, error)
                        }
                    }
                }

                return content
            })()

            // console.log(mdData)
            fs.writeFileSync(`${writePath}/${slug}.md`, mdHeader + mdData)
        }
    } catch (error) {
        console.error('Error processing pages:', error)
    }
})()
