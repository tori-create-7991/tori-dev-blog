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
| `/tweets` | X / Bluesky / Threads への投稿ログ（text-sns-relay 連携） |

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

各種コンテンツ取り込みスクリプトを使う場合は以下の環境変数を `.env` に設定:

```
# 記事取り込み（scripts/getNotiontoMd.ts）
NOTION_API_KEY=
NOTION_DATABASE_ID=
# Google Drive 取り込み（scripts/getGoogleDrive.ts）
GOOGLE_APPLICATION_CREDENTIALS=
# つぶやき取り込み（scripts/getTweetsFromNotion.ts、text-sns-relay連携）
NOTION_TWEETS_DB_ID=641e0e88-38b8-466a-98e4-d53aa4bd9432
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
npm run get-tweets   # Notion「つぶやきログ」DB → content/tweets/*.md
```

### 記事クロスポスト（article-relay）

別リポ `article-relay` から手動実行、または push 時に自動実行（下記参照）:

```bash
cd ../article-relay
npm run cross -- ../tori-dev-blog/content/posts/<slug>.md
```

`content/posts/*.md` の frontmatter で `cross_post: { qiita: true, zenn: true }` を立てた記事だけが対象。

## リポジトリ間連携（疎結合、docs/design/cross-repo-loose-coupling.md 参照）

tori-dev-blog / article-relay / text-sns-relay はそれぞれ単独動作可能な
独立リポジトリ。以下の2つの連携は「実行時トリガー」「共有データストア」の
形でのみ疎通し、コードレベルの依存は持たない。

### 1. blog → article-relay（自動クロスポスト）

`.github/workflows/detect-cross-post.yml` が `content/posts/*.md` の変更を
検知し、`cross_post` フラグが立った記事を GitHub の `repository_dispatch`
で article-relay に送信。article-relay 側の
`.github/workflows/cross-post-dispatch.yml` が受け取って `npm run cross` を
実行する。

必要な GitHub Secret（本リポジトリ側）:

| Secret | 用途 |
|---|---|
| `ARTICLE_RELAY_DISPATCH_TOKEN` | article-relay への `repository_dispatch` 送信用 Fine-grained PAT（`actions:write` のみ） |

### 2. text-sns-relay → blog（`/tweets` ページ）

text-sns-relay が投稿成功時に Notion DB「つぶやきログ」へ書き込み、blog が
ビルド時に `npm run get-tweets` で取得して `/tweets` ページに反映する
（ADR 0003）。両リポジトリとも同じ `NOTION_TOKEN` / DB ID を使用。

## 開発フェーズ

| Phase | 内容 | Status |
|---|---|---|
| 1 | `/advisory` ページ + article-relay 連携 frontmatter | ✓ |
| 1.5 | Terraform / Firebase Hosting 移植（コード・runbook 準備まで） | ✓（PR待ち） |
| 2 | `/tweets`（text-sns-relay 連携）+ cross-repo自動連携（Notion経由） | ✓ |
| 2.5 | ニュースレター + Works タブ | 検討中 |
| 3 | デザイン刷新 + Works / About 全面リニューアル + `/contact` API | 検討中 |

## 関連プロジェクト

| リポ | 役割 |
|---|---|
| [article-relay](https://github.com/tori-create-7991/article-relay) | 本ブログ記事を Qiita / Zenn にクロスポスト |
| [text-sns-relay](https://github.com/tori-create-7991/text-sns-relay) | X / Bluesky / Threads へ投稿、Slack / Discord 通知（つぶやき導線） |
| [bonsaidev](https://github.com/tori-create-7991/bonsaidev) | 自律エージェント FW |
| [whv-compass](https://github.com/tori-create-7991/whv-compass) | AI 相談 SaaS（豪 WHV 向け） |

## 連絡先

[tori-dev.com/advisory](https://tori-dev.com/advisory) からお願いします。
