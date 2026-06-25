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
  advisoryPath: "/advisory",
};

export const sidebarItem = [
  {
    title: "Top",
    to: "/",
  },
  {
    title: "About",
    to: "/sidecontent/about",
  },
  {
    title: "顧問サービス",
    to: "/advisory",
  },
];

export const footerItem = [
  {
    title: "プライバシーポリシー等",
    to: "/sidecontent/policy",
  },
  {
    title: "問い合わせ",
    to: "/sidecontent/contact",
  },
  {
    title: "顧問契約のご相談",
    to: "/advisory",
  },
];


// announcements on/off
export const announcementsFlag = false
