import { defineContentConfig, defineCollection,z } from '@nuxt/content'

export default defineContentConfig({
  collections: {
    content: defineCollection({
      type: 'page',
      source: '**/*.md'
    }),
    posts: defineCollection({
      source: 'posts/*.md',
      type: 'page',
      schema: z.object({
        title: z.string(),
        description: z.string(),
        date: z.date(),
        image: z.string(),
        tags: z.array(z.string()),
        categories: z.array(z.string()),
        // article-relay cross-post integration
        cross_post: z
          .object({
            qiita: z.boolean().optional(),
            zenn: z.boolean().optional(),
            note: z.boolean().optional(),
            devto: z.boolean().optional(),
          })
          .optional(),
        qiita_url: z.string().nullable().optional(),
        qiita_id: z.string().nullable().optional(),
        zenn_url: z.string().nullable().optional(),
        zenn_slug: z.string().nullable().optional(),
        zenn_emoji: z.string().optional(),
        zenn_type: z.enum(['tech', 'idea']).optional(),
        note_url: z.string().nullable().optional(),
        note_id: z.string().nullable().optional(),
        private: z.boolean().optional(),
        topics: z.array(z.string()).optional(),
      }),
    }),
    // docs: defineCollection({
    //   // Load every file inside the `content` directory
    //   source: '**',
    //   // Specify the type of content in this collection
    //   type: 'page'
    // }),
    announcements: defineCollection({
      source: 'announcements/*.md',
      type: 'page',
      schema: z.object({
        title: z.string(),
        description: z.string(),
        date: z.date(),
        image: z.string(),
        advertisements: z.array(z.string()),
      }),
    }),
    sideContent: defineCollection({
      // ファイルはcontent/sidecontent/配下のまま、URLは/sidecontent/を外してflat化する
      source: { include: 'sidecontent/*.md', prefix: '/' },
      type: 'page',
    }),
    service: defineCollection({
      source: 'service/*.md',
      type: 'page',
      schema: z.object({
        title: z.string(),
        description: z.string(),
        category: z.enum(['advisory', 'training', 'development']),
        price: z.string().optional(),
        features: z.array(z.string()).optional(),
      }),
    }),
    feed: defineCollection({
      source: 'feed/*.md',
      type: 'page',
      schema: z.object({
        title: z.string(),
        date: z.date(),
        sourceUrl: z.string().optional(),
        platform: z.enum(['x', 'bluesky', 'instagram']).optional(),
      }),
    }),
    works: defineCollection({
      source: 'works/*.md',
      type: 'page',
      schema: z.object({
        title: z.string(),
        description: z.string(),
        category: z.enum(['ax-dx', 'training', 'development']),
        date: z.date(),
        technologies: z.array(z.string()).optional(),
        role: z.string().optional(),
        duration: z.string().optional(),
        links: z
          .array(z.object({ text: z.string(), url: z.string() }))
          .optional(),
      }),
    }),

  }
})
