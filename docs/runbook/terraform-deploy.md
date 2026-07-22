# Runbook: Terraform / Firebase Hosting 初回デプロイ

このリポジトリの Terraform / GitHub Actions は用意済みだが、実際の GCP
リソース作成・GitHub Secrets 設定・DNS 変更は **GCP・Cloudflare の認証情報を
保有するユーザー自身が実行する**。以下の手順に沿って進める。

関連: `docs/design/terraform-firebase-hosting-migration.md`,
`docs/adr/0001-reuse-gcp-project-new-hosting-site.md`

## 前提

- GCP project `tori-develop` へのオーナー/編集者権限
- `gcloud` CLI ログイン済み（`gcloud auth login`）
- `terraform` CLI インストール済み
- GitHub リポジトリ `tori-create-7991/tori-dev-blog` への admin 権限
  （Secrets/Variables 設定のため）
- カスタムドメイン設定時のみ: GCP project `tori-dev-secrets`
  （組織 `tori-create.org` / 請求先 `tori-dev`）の secret
  `cloudflare-tori-dev-dns-token` への `secretmanager.secretAccessor` 権限
  （`cloudflare-tori-dev-deploy-token` は現構成では未使用）
  - `tori-develop`（本体プロジェクト）と `tori-dev-secrets` の権限アカウントが
    異なるテナントの場合、組織ポリシーでIAMをアカウント間共有できないことが
    ある。その場合は両アカウントを個別に `gcloud auth login` しておき、
    `SECRET_ACCOUNT` 環境変数で `tori-dev-secrets` 側アカウントを指定する
    （下記手順2参照）

## 手順

### 1. GCS backend 用バケットの確認・作成

Terraform state を保存する GCS バケットが必要（`terraform/providers.tf` の
`backend "gcs" { prefix = "terraform/blog" }`）。

```bash
# 既存バケットがあるか確認（旧 012_nuxt-07_nuxt3_toriblog の tori-dev ブランチ
# で使っていたバケットを流用できるか要確認）
gsutil ls -p tori-develop

# 無ければ新規作成
gsutil mb -p tori-develop -l asia-northeast1 gs://<バケット名>
```

バケット名を控えておく（後で GitHub Secret `GCP_TF_STATE_BUCKET` に設定）。

### 2. GCP 初期セットアップスクリプトを実行

```bash
cd tori-dev-blog
bash scripts/setup_gcp.sh
```

対話式で以下を入力（環境変数で事前指定も可）:

```bash
export PROJECT_ID="tori-develop"
export GH_REPO="tori-create-7991/tori-dev-blog"
# tori-develop と tori-dev-secrets の権限アカウントが別テナントの場合のみ:
# export SECRET_ACCOUNT="tori-develop側とは別の、tori-dev-secretsにアクセスできるアカウント"
# カスタムドメインは今回のスコープ外のため空のままでよい
# export CUSTOM_DOMAIN=""
bash scripts/setup_gcp.sh
```

このスクリプトは冪等（既存リソースがあれば import、無ければ新規作成）。
実行後、以下が GCP 側に作成される:

- WIF Pool `github-pool`（既存なら再利用）
- WIF Provider `tori-dev-blog-provider`（このリポジトリ専用）
- Service Account `github-actions-tori-blog`
- 必要な IAM ロール付与

スクリプト完了時、`gh` CLI がログイン済み・対象リポジトリへの admin
権限があれば以下の Secret を **自動登録**する（`gh secret set`）:

| GitHub Secret | 値 |
|---|---|
| `WIF_PROVIDER` | スクリプト出力の `wif_provider` |
| `GCP_SA_EMAIL` | スクリプト出力の `sa_email` |
| `GCP_PROJECT_ID` | `tori-develop` |
| `GCP_TF_STATE_BUCKET` | 手順1で確認したバケット名 |
| `CLOUDFLARE_API_TOKEN` | `CUSTOM_DOMAIN` 設定時のみ。GCP Secret Manager (project `tori-dev-secrets`, secret `cloudflare-tori-dev-dns-token`) から自動取得 |
| `CLOUDFLARE_ZONE_ID` | `CUSTOM_DOMAIN` 設定時のみ。取得したトークンで Cloudflare API を叩いて自動導出 |

`gh` 未検出・未認証の場合は登録コマンド例を標準出力するので、手動で実行する。
`CLOUDFLARE_API_TOKEN` の Secret Manager 取得に失敗した場合（権限不足・secret名不一致）は手動入力にフォールバックする。

`cloudflare-tori-dev-deploy-token` は現構成では未使用（配線しない）。
**TODO（将来検討）**: Cloudflare Pages/Workers 等、DNS操作を伴わないデプロイ系
タスクを追加する際に使う想定で残置。使う段になったら、このスクリプトの
`CLOUDFLARE_DNS_TOKEN_SECRET` と同様に別変数（例:
`CLOUDFLARE_DEPLOY_TOKEN_SECRET`）で `gcloud secrets versions access` させ、
用途に応じた最小権限の GitHub Secret として登録する。

以下は自動登録の対象外（別途手動で設定）:

| GitHub Secret | 値 |
|---|---|
| `DOTENV` | ブログの `.env` 相当の中身（Notion/Google 連携が必要な場合のみ） |

GitHub Variables（`vars`）:

| Variable | 値 | 備考 |
|---|---|---|
| `FIREBASE_SITE_SUFFIX` | `blog`（デフォルトのため省略可） | site_id = `tori-develop-blog` |
| `CLOUDRUN_SERVICE_NAME` | `tori-dev-blog`（デフォルトのため省略可） | 未使用（`deploy_target=firebase`） |
| `CUSTOM_DOMAIN` | 空のまま（このタスクのスコープ外） | 設定するとカスタムドメイン紐付けが Terraform で走るため要注意 |

### 3. GitHub Actions を実行

`main` ブランチに push するか、`workflow_dispatch` で手動実行:

```bash
gh workflow run firebase-hosting-deploy.yml
```

ワークフローが以下を実行する:

1. WIF 認証
2. `terraform init` / `terraform apply`（Firebase Hosting サイト `tori-develop-blog` を新規作成）
3. Nuxt3 SSG ビルド（`npm run generate`）
4. `firebase deploy --only hosting:blog`

### 4. 動作確認

```bash
curl -I https://tori-develop-blog.web.app
```

`200` が返れば成功。**この時点では tori-dev.com の DNS には一切触れていない**
ため、現行の旧 Nuxt2 サイトは無停止のまま。

### 5. カスタムドメイン切替（このタスクのスコープ外・別途判断）

新サイトの内容を確認して問題なければ、以下を検討する（本 runbook は準備
のみで、実行判断・実施は別セッションで行う）:

- Firebase Console から `tori-develop-blog` サイトにカスタムドメイン
  `tori-dev.com` を追加
- DNS レコード（Cloudflare）を新サイト向けに更新
- 旧 default サイト（Nuxt2）の扱いを決める（削除 / 別ドメインで保持 等）

**注意**: この手順は本番ドメインへの影響が大きいため、実行前に必ず
バックアップ・ロールバック手順を確認すること。
