# tori-dev-blog

[tori-dev.com](https://tori-dev.com) のソースコード。技術ブログ、つぶやき、つくったものを置いている個人サイト。

フォークして自分のサイトを作ることもできる。インフラは Terraform でコード化してあり、
GCP と GitHub があれば同じ構成を再現できる（[docs/setup/fork.md](docs/setup/fork.md)）。

## ページ

| パス | 内容 |
|---|---|
| `/` | トップ |
| `/posts`・`/posts/<slug>` | ブログ記事 |
| `/category`・`/tag` | カテゴリ・タグ別の記事一覧 |
| `/feed` | X・Bluesky・Instagram の投稿（つぶやき） |
| `/works` | つくったもの・関わったもの |
| `/service` | 提供していること |
| `/about`・`/contact`・`/policy` | プロフィール・問い合わせ・プライバシーポリシー |
| `/sitemap.xml`・`/rss.xml`・`/robots.txt` | ビルド時に生成 |

## 技術スタック

| 層 | 技術 |
|---|---|
| サイト | Nuxt 3（全ページを事前生成）、@nuxt/content v3、@nuxt/ui、Tailwind CSS 4、Pinia、fuse.js |
| 配信 | Firebase Hosting（本番サイトと、PR ごとのプレビューチャネルを置く検証サイト） |
| DNS | Cloudflare（DNS only） |
| インフラ | Terraform 2 段構成（`terraform/bootstrap` は人がローカルで、`terraform/app` は CI が apply）。[ADR 0006](docs/adr/0006-two-stage-terraform.md) |
| CI | GitHub Actions。PR でビルド・プレビュー・plan、main で apply と配信。Secrets は使わない（Workload Identity Federation） |
| 依存の更新 | Dependabot（週 1 回）。Actions はコミット SHA で固定 |

## 開発

```bash
git clone https://github.com/tori-create-7991/tori-dev-blog.git
cd tori-dev-blog
npm ci
npm run dev        # http://localhost:3000
npm run generate   # .output/public/ に静的サイトを生成
```

ビルドと開発サーバに環境変数は要らない。

| コマンド | 内容 |
|---|---|
| `npm run generate-og` | 記事タイトルから OG 画像を生成（Python + Pillow） |
| `npm run check-drafts` | ビルド結果に下書きが混ざっていないか検査 |
| `npm run submit-indexnow` | IndexNow に更新を通知（CI が本番配信後に実行） |

Notion・Google Drive から記事を取り込む任意の道具は [docs/content-import.md](docs/content-import.md)。

## デプロイとインフラ

- PR を出すと、ビルドして PR ごとのプレビュー URL と Terraform の plan が PR にコメントされる。
- main にマージすると、CI が `terraform/app` を apply し、本番へ配信する。
- 権限・DNS・GitHub 設定（`terraform/bootstrap`）はローカルで apply する。

運用手順は [docs/runbook/terraform-deploy.md](docs/runbook/terraform-deploy.md)。

## 記事のクロスポスト

[article-relay](https://github.com/tori-create-7991/article-relay) で Qiita・Zenn に転載する。
`content/posts/*.md` の frontmatter で `cross_post: { qiita: true, zenn: true }` を立てた記事が対象。

```bash
cd ../article-relay
npm run cross -- ../tori-dev-blog/content/posts/<slug>.md
```

## ライセンス

- **コード**（`.ts`、`.vue`、`.js`、CSS、設定ファイルなど）: MIT（[LICENSE](LICENSE)）
- **記事**（`content/` 配下）と**画像**（`public/` 配下）: All Rights Reserved（[docs/content-license.md](docs/content-license.md)）

引用は出典を明示すれば歓迎。商用利用・再配布は事前に相談してください。

## セキュリティ

脆弱性は公開の Issue ではなく、非公開の脆弱性報告で知らせてください（[SECURITY.md](SECURITY.md)）。
