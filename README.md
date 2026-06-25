# tori-dev-blog

[tori-dev.com](https://tori-dev.com) のソースコード。**中小企業の AI 導入・DX 顧問**としての活動拠点となるブログ＆ポートフォリオ。

> 受託デリバリではなく、**顧問・ストック型** で長期に伴走するスタイルを目指しています。
> 現役で農家の AI 導入支援、過去に DX 支援。OSS と自社プロダクトの運営者でもあります。

## 構成

| 領域 | 用途 |
|---|---|
| `/` (Home) | Hero ＋ 最新記事 ＋ 顧問 CTA |
| `/posts` | 自前ブログ記事（@nuxt/content v3 ベース） |
| `/advisory` | 顧問契約の提供価値・料金・FAQ・問い合わせ |
| `/sidecontent/about` | プロフィール |
| `/sidecontent/contact` | お問い合わせ |
| `/sidecontent/policy` | プライバシーポリシー |

## 技術スタック

- **Framework**: Nuxt 3 + @nuxt/content v3 + @nuxt/ui (Reka UI + Tailwind)
- **State**: Pinia
- **Search**: fuse.js
- **CMS 統合**: Notion API (`notion-to-md`), Google Drive (`googleapis`)
- **Hosting**: Firebase Hosting（SSG）+ Cloud Functions（フォーム受口、Phase 2 以降）
- **Cross-post**: [tori-create-7991/article-relay](https://github.com/tori-create-7991/article-relay) — Qiita / Zenn にブログ記事をクロスポストする CLI

## ライセンス

- **コード**（`.ts`, `.vue`, 設定ファイル等）: **MIT**（[`LICENSE`](LICENSE) 参照）
- **記事**（`content/posts/*.md` ほか）と **画像** (`public/images/`, `assets/`): **All Rights Reserved**

引用は出典明示で歓迎。商用利用・再配布は事前にご相談ください。

## セットアップ

```bash
git clone https://github.com/tori-create-7991/tori-dev-blog.git
cd tori-dev-blog
cp .env.example .env  # 必要に応じて作成
npm install
```

`scripts/getNotiontoMd.ts` / `scripts/getGoogleDrive.ts` を使う場合は以下の環境変数を `.env` に設定:

```
NOTION_TOKEN=
GOOGLE_APPLICATION_CREDENTIALS=
```

### 開発サーバ

```bash
npm run dev
# → http://localhost:3000
```

### ビルド（SSG）

```bash
npm run generate
# → .output/public/ に静的サイト生成
```

### コンテンツ取り込み

```bash
npm run get-notion   # Notion DB → content/posts/*.md
npm run get-drive    # Google Drive → public/images/
```

### 記事クロスポスト

別リポ `article-relay` から:

```bash
cd ../article-relay
npm run cross -- ../tori-dev-blog/content/posts/<slug>.md
```

`content/posts/*.md` の frontmatter で `cross_post: { qiita: true, zenn: true }` を立てた記事だけが対象。

## 開発フェーズ

| Phase | 内容 | Status |
|---|---|---|
| 1 | `/advisory` ページ + article-relay 連携 frontmatter | ✓ |
| 2 | `/tweets`（つぶやき集約 / x-times-relay 連携）+ ニュースレター + Works タブ | 検討中 |
| 3 | デザイン刷新 + Works / About 全面リニューアル + `/contact` API + Terraform 化 | 検討中 |

## 関連プロジェクト

| リポ | 役割 |
|---|---|
| [article-relay](https://github.com/tori-create-7991/article-relay) | 本ブログ記事を Qiita / Zenn にクロスポスト |
| [x-times-relay](https://github.com/tori-create-7991/x-times-relay) | X 投稿を Slack / Discord に転送（つぶやき導線） |
| [bonsaidev](https://github.com/tori-create-7991/bonsaidev) | 自律エージェント FW |
| [whv-compass](https://github.com/tori-create-7991/whv-compass) | AI 相談 SaaS（豪 WHV 向け） |

## 連絡先

[tori-dev.com/advisory](https://tori-dev.com/advisory) からお願いします。
