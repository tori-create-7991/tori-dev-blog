# Design Doc: Terraform / Firebase Hosting 移植（Option A）

## Context and Scope

tori-dev-blog（本リポジトリ）は 2026-06-25 に `012_nuxt-07_nuxt3_toriblog` の
`master` ブランチを起点として public リポで再スタートした。しかし同リポの
**`tori-dev` ブランチ**（GitHub push 済み、private）に、今回の `master` には
含まれていなかった以下の資産が既に存在することが判明した:

- Terraform 一式（`terraform/`）: Firebase Hosting + Cloud Run + Cloudflare DNS
  + WIF(Workload Identity Federation) による GitHub Actions 認証
- GitHub Actions ワークフロー（`.github/workflows/firebase-hosting-deploy.yml`）
- GCP 初期セットアップスクリプト（`scripts/setup_gcp.sh`、実環境検証済み）
- content-sync（Notion/Google Drive → `content/posts/` 取込）
- Gemini AI による eyecatch 画像自動生成

本 Design Doc は **Option A: Terraform 一式のみ** を tori-dev-blog に移植する
スコープを扱う。content-sync / eyecatch は対象外（別タスクで後日移植）。

## Goals / Non-Goals

### Goals

- 現行 tori-dev.com（Nuxt2/Vuetify, Firebase Hosting, project `tori-develop`）
  を **止めずに**、新 Nuxt3 サイトを同一 GCP project 内の**別 Firebase Hosting
  サイト**としてデプロイできる状態にする
- push トリガーで Terraform apply → SSG build → Firebase Hosting deploy が
  自動実行される GitHub Actions を用意する
- WIF 認証（SA Key JSON 不使用）でセキュアな CI/CD を維持する
- 既存 `tori-dev` ブランチの検証済み構成を尊重し、リポジトリ名の変更
  （`012_nuxt-07_nuxt3_toriblog` → `tori-dev-blog`）に合わせて WIF Provider
  だけ作り直す

### Non-Goals

- content-sync（Notion/Drive 取込）・eyecatch 自動生成の移植（別タスク）
- 本番カスタムドメイン（tori-dev.com）の実際の切替 — 新サイトの
  `*.web.app` URL 動作確認までがこのタスクのゴール。ドメイン切替は
  本番影響が大きい別ステップとして扱う
- 実際の `terraform apply` 実行・GCP リソース作成・Cloudflare DNS 変更の
  自動実行 — コード・設定は用意するが、実行は明示確認の上で行う
  （GCP/Cloudflare の認証情報はユーザー保有のため）

## Background

- 現行本番: DNS `tori-dev.com` → A record `199.36.158.100`
  （Firebase Hosting 予約 IP）。GCP project は `.firebaserc` より
  `tori-develop`
- `tori-dev` ブランチの `terraform/iam.tf` は WIF Pool `github-pool` を
  **business-card リポジトリ等と共有**する設計（Pool 自体は
  `scripts/setup_gcp.sh` の gcloud コマンドで別途確保済み、Provider だけ
  リポジトリ単位で追加）
- `firebase_hosting.tf` の `site_id` は `${project_id}-${firebase_site_suffix}`
  （デフォルト suffix `blog`）→ 例: `tori-develop-blog`。これは**既存の
  default サイト（旧 Nuxt2 ブログ）とは別サイト**として作成されるため、
  適用しても本番影響はゼロ

## Design / System Context

```
GitHub (tori-create-7991/tori-dev-blog)
  push to main
        │
        ▼
GitHub Actions (firebase-hosting-deploy.yml)
  1. WIF 認証 (google-github-actions/auth@v2)
  2. terraform init (GCS backend: prefix terraform/blog)
  3. terraform apply
        │
        ▼
GCP project: tori-develop (既存を再利用)
  ├─ Firebase Hosting site: tori-develop-blog (新規、既存 default サイトと分離)
  ├─ WIF Provider: tori-dev-blog-provider (新規、リポジトリ単位)
  ├─ Service Account: github-actions-blog (新規 or 既存 import)
  └─ (Cloud Run 資産は保持するが今回未使用、deploy_target=firebase)
        │
        ▼
GitHub Actions (続き)
  4. npm run generate (Nuxt3 SSG → .output/public)
  5. firebase deploy --only hosting:blog
        │
        ▼
https://tori-develop-blog.web.app  ← 動作確認ポイント（このタスクのゴール）

（カスタムドメイン切替は別タスク・別確認）
```

## Alternatives Considered

1. **tori-dev ブランチを丸ごとマージ**（terraform + content-sync + eyecatch）
   — 却下。content-sync 側の frontmatter schema が tori-dev-blog の
   `cross_post` schema と衝突する可能性があり、今回のスコープ外の変更が
   混ざるとレビュー・切り戻しが難しくなる
2. **tori-dev-blog を破棄し tori-dev ブランチをベースに作り直す** — 却下。
   今日実装した `/advisory` ページ・LICENSE・README 等の Phase 1 成果を
   再適用する手間が生じるうえ、public リポとして一度 push 済みの履歴を
   破棄することになる
3. **新規 GCP project を作る** — 却下。ドメイン・課金・既存 IAM が
   `tori-develop` に紐づいており、project 分離のメリットが薄い。
   Firebase Hosting の multi-site 機能で同一 project 内に安全に共存できる

## Risks / Concerns

| リスク | 対処 |
|---|---|
| WIF Pool 共有によりリポジトリ間で権限が混線する | Provider は `attribute_condition = assertion.repository == "tori-create-7991/tori-dev-blog"` でリポジトリ単位に限定（既存パターン踏襲） |
| GCS backend 用バケットが存在しない可能性 | `terraform init` 実行前にバケット存在確認が必要（ユーザー確認事項） |
| firebase.json の `public` ディレクトリが旧 Nuxt2 用（`dist`）のまま | 新規に `.output/public`（Nuxt3 generate 出力）を指す `firebase.json` を作成 |
| 実際の `terraform apply` / secret 設定はこのセッションで自動実行しない | GCP・Cloudflare 認証情報はユーザー保有。コード・workflow・runbook まで用意し、適用はユーザー確認の上で実施 |

## Success Metrics

- [ ] `terraform validate` / `terraform plan`（ローカル or CI dry run）がエラーなく通る
- [ ] GitHub Actions の WIF Provider / Service Account が GCP 側に作成される
- [ ] `https://tori-develop-blog.web.app` が Nuxt3 SSG ビルドを 200 で返す
- [ ] 既存 tori-dev.com（旧サイト）が無停止で動作し続けている
