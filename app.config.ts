export default defineAppConfig({
  ui: {
    colors: {
      primary: 'neutral',
      // 実際の色は assets/css/main.css で --ui-color-secondary-* を
      // サイトのアクセント(セージ #A2A897)に上書きしている。
      // ここのパレット名は @nuxt/ui にスケールを解決させるための土台にすぎない
      secondary: 'violet',
      neutral: 'neutral',
    },
  },
})
