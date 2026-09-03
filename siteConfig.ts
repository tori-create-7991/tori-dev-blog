export const siteConfig = {
  siteTitle: "tori-dev",
  // title の共通テンプレート。各ページは素のタイトルだけを渡す
  titleTemplate: "%s | tori-dev",
  twitterUrl: "",
  facebookUrl: "",
  instagramUrl: "",
  baseColor: true,
  defaultImage: "/default.jpg",
  // OGP 既定画像。1200x630 の絶対URLとして出力する（siteUrl と連結）
  defaultOgImage: "/og-default.png",
  description: '中小企業の AI 導入・DX を月次で。AI エージェント開発と顧問業のブログ＆ポートフォリオ',
  lang: 'ja',
  locale: 'ja_JP',
  welcomeMessage: "Welcome to tori-dev.",
  // 顧問契約 CTA（リード獲得の主導線）
  advisoryCtaLabel: "顧問契約のご相談",
  advisoryPath: "/service/advisory",
};

// 外部プロフィール。JSON-LD の Person.sameAs とフッターの rel="me" リンクに使う。
// url が空の項目は出力されないので、アカウントが確定したら埋めるだけでよい。
export const socialProfiles = [
  { key: "github", label: "GitHub", url: "https://github.com/tori-create-7991" },
  { key: "x", label: "X", url: "" },
  { key: "bluesky", label: "Bluesky", url: "" },
  { key: "zenn", label: "Zenn", url: "" },
  { key: "qiita", label: "Qiita", url: "" },
  { key: "note", label: "note", url: "" },
];

export const activeSocialProfiles = () => socialProfiles.filter((p) => p.url);

// works の category(enum) → 表示ラベル・表示順。content.config.tsのenum定義と手動同期する
export const workCategories = [
  { key: "ax-dx", label: "AX・DX" },
  { key: "training", label: "研修" },
  { key: "development", label: "開発" },
];

export const workCategoryLabel = (key) =>
  workCategories.find((c) => c.key === key)?.label || key;

// service の category(enum) → 表示ラベル・表示順。content.config.tsのenum定義と手動同期する
export const serviceCategories = [
  { key: "advisory", label: "顧問" },
  { key: "training", label: "講師" },
  { key: "development", label: "開発" },
];

export const serviceCategoryLabel = (key) =>
  serviceCategories.find((c) => c.key === key)?.label || key;

export const authorName = "利根川 諒";
export const authorAlternateName = "Ryo Tonegawa";
export const authorJobTitle = "フリーランスエンジニア / 中小企業のAI導入・DX顧問";
export const authorArea = "長野県";
// Person.knowsAbout。エンティティの専門領域を明示する
export const authorKnowsAbout = [
  "中小企業のAI導入",
  "DX顧問",
  "AIエージェント開発",
  "ERPシステム開発",
  "プログラミング講師",
  "Nuxt",
  "TypeScript",
];

// ヘッダー・フッターのナビゲーション。
// title=日本語（主）/ en=英語（補助表示）。中小企業の意思決定者に読ませる前提で日本語を主にする。
export const sidebarItem = [
  {
    title: "ホーム",
    en: "Top",
    to: "/",
  },
  {
    title: "実績",
    en: "Works",
    to: "/works",
  },
  {
    title: "サービス",
    en: "Service",
    to: "/service",
  },
  {
    title: "ブログ",
    en: "Blog",
    to: "/posts",
  },
  {
    title: "つぶやき",
    en: "Feed",
    to: "/feed",
  },
  {
    title: "プロフィール",
    en: "About",
    to: "/about",
  },
  {
    title: "ご相談",
    en: "Contact",
    to: "/contact",
  },
];

// sitemap 等でヘッダーに出さないページも含めた全体の導線。
// つぶやき(Feed)は 2026-09 にヘッダー導線(sidebarItem)へ戻したため現在は空
export const secondaryItem = [];

export const footerItem = [
  {
    title: "プライバシーポリシー等",
    to: "/policy",
  },
  {
    title: "問い合わせ",
    to: "/contact",
  },
  {
    title: "顧問契約のご相談",
    to: "/service/advisory",
  },
];


// announcements on/off
export const announcementsFlag = false

// つぶやき(Feed)を公開するか。false にすると noindex + sitemap 除外 + フッター非表示になる。
// /feed ページ自体は投稿 0 件の間は feedPublished に関わらず noindex のまま(pages/feed/index.vue)。
export const feedPublished = true
