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
  description: 'tori-dev の個人サイト。技術ブログ、つぶやき、つくったものを置いています。',
  lang: 'ja',
  locale: 'ja_JP',
  welcomeMessage: "Welcome to tori-dev.",
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

export const authorName = "Ryo Tonegawa";
export const authorAlternateName = "Tori";
export const authorJobTitle = "エンジニア";
export const authorArea = "長野県";
// Person.description。サイト説明ではなく人物の説明を入れる
export const authorDescription = "AI エージェントと業務システムをつくっているエンジニア。";
// Person.knowsAbout。エンティティの専門領域を明示する
export const authorKnowsAbout = [
  "AIエージェント開発",
  "業務システム開発",
  "Nuxt",
  "TypeScript",
  "Java",
  "Python",
];

// ヘッダー・フッターのナビゲーション。
// ラベルは英語のみ（日英併記はしない）。個人サイトなので問い合わせ導線はヘッダーに置かない。
export const sidebarItem = [
  {
    title: "Home",
    to: "/",
  },
  {
    title: "Blog",
    to: "/posts",
  },
  {
    title: "Feed",
    to: "/feed",
  },
  {
    title: "Works",
    to: "/works",
  },
  {
    title: "Service",
    to: "/service",
  },
  {
    title: "About",
    to: "/about",
  },
];

// sitemap 等でヘッダーに出さないページも含めた全体の導線。
// つぶやき(Feed)は 2026-09 にヘッダー導線(sidebarItem)へ戻したため現在は空
export const secondaryItem = [];

export const footerItem = [
  {
    title: "Privacy Policy",
    to: "/policy",
  },
  {
    title: "Contact",
    to: "/contact",
  },
];


// announcements on/off
export const announcementsFlag = false

// つぶやき(Feed)を公開するか。false にすると noindex + sitemap 除外 + フッター非表示になる。
// /feed ページ自体は投稿 0 件の間は feedPublished に関わらず noindex のまま(pages/feed/index.vue)。
export const feedPublished = true
