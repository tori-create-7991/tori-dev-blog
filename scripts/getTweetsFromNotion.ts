// text-sns-relay が書き込む Notion DB「つぶやきログ」から取得し、
// content/tweets/*.md を生成する（docs/adr/0003 参照）。
// getNotiontoMd.ts と同じ Notion クライアント利用パターンを踏襲。
import { Client } from '@notionhq/client'
import type { PageObjectResponse } from '@notionhq/client'
import fs from 'fs'
import path from 'path'
import dotenv from 'dotenv'

dotenv.config()

const apiKey = process.env.NOTION_API_KEY
const databaseId = process.env.NOTION_TWEETS_DB_ID

if (!apiKey || !databaseId) {
    throw new Error('NOTION_API_KEY / NOTION_TWEETS_DB_ID が環境変数に設定されていません')
}

const writePath = './content/tweets'

if (!fs.existsSync(writePath)) {
    fs.mkdirSync(writePath, { recursive: true })
}

const notion = new Client({ auth: apiKey })

function escapeYamlString(s: string): string {
    return s.replace(/"/g, '\\"').replace(/\n/g, ' ')
}

;(async () => {
    try {
        const pageList = await notion.databases.query({
            database_id: databaseId,
            sorts: [{ property: 'PostedAt', direction: 'descending' }],
        })

        for (const iterator of pageList.results) {
            const res = iterator as PageObjectResponse
            const props = res.properties

            const text =
                props.Text?.type === 'title' && props.Text.title[0]
                    ? props.Text.title.map((t) => t.plain_text).join('')
                    : ''

            const platforms =
                props.Platforms?.type === 'multi_select'
                    ? props.Platforms.multi_select.map((p) => p.name)
                    : []

            const postedAt =
                props.PostedAt?.type === 'date' && props.PostedAt.date
                    ? props.PostedAt.date.start
                    : ''

            const urlX =
                props.URL_X?.type === 'url' ? props.URL_X.url ?? '' : ''
            const urlBluesky =
                props.URL_Bluesky?.type === 'url' ? props.URL_Bluesky.url ?? '' : ''
            const urlThreads =
                props.URL_Threads?.type === 'url' ? props.URL_Threads.url ?? '' : ''

            if (!text || !postedAt) continue

            const slug = res.id.replace(/-/g, '')
            const platformsYaml = platforms.map((p) => `  - ${p}`).join('\n')

            const md = `---
title: "${escapeYamlString(text.slice(0, 60))}"
text: "${escapeYamlString(text)}"
postedAt: ${postedAt}
platforms:
${platformsYaml || '  []'}
urlX: "${urlX}"
urlBluesky: "${urlBluesky}"
urlThreads: "${urlThreads}"
---
`
            fs.writeFileSync(path.join(writePath, `${slug}.md`), md)
        }

        console.log(`つぶやき ${pageList.results.length} 件を取得しました`)
    } catch (error) {
        console.error('Error fetching tweets from Notion:', error)
        process.exit(1)
    }
})()
