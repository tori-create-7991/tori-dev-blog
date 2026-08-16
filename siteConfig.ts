export const siteConfig = {
  siteTitle: "tori-dev",
  twitterUrl: "",
  facebookUrl: "",
  instagramUrl: "",
  baseColor: true,
  defaultImage: "/default.jpg",
  description: '中小企業の AI 導入・DX を月次で。AI エージェント開発と顧問業のブログ＆ポートフォリオ',
  lang: 'ja',
  welcomeMessage: "Welcome to tori-dev.",
  // 顧問契約 CTA（リード獲得の主導線）
  advisoryCtaLabel: "顧問契約のご相談",
  advisoryPath: "/service/advisory",
};

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

export const sidebarItem = [
  {
    title: "Top",
    to: "/",
  },
  {
    title: "About",
    to: "/about",
  },
  {
    title: "Works",
    to: "/works",
  },
  {
    title: "Blog",
    to: "/posts",
  },
  {
    title: "Service",
    to: "/service",
  },
  {
    title: "Feed",
    to: "/feed",
  },
];

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
