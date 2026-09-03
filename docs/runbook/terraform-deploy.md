# Runbook: Terraform / Firebase Hosting 初回デプロイ

このリポジトリの Terraform / GitHub Actions は用意済みだが、実際の GCP
リソース作成・GitHub Secrets 設定・DNS 変更は **GCP・Cloudflare の認証情報を
保有するユーザー自身が実行する**。以下の手順に沿って進める。

> **既知の実インシデント（2026-07-22）**: `terraform/providers.tf` の GCS
> backend prefix が当初 `terraform/blog` という汎用名だったため、同一 GCS
> バケット（`tori-develop-tfstate`）を共有していた旧 Nuxt3 ブログリポジトリ
> （`012_nuxt-07_nuxt3_toriblog`、`tori-dev.com` 本番運用中）の state と衝突。
> `terraform apply` が旧リポジトリの稼働中リソース（Service Account の
> project-level IAMロール9個、WIF Provider、Artifact Registry）を「別名への
> リネーム」と誤認識し、破壊 → 再作成した。手動でIAMロール再付与・WIF
> Provider undelete・Artifact Registry再作成（中身のDockerイメージは復元
> 不可）で復旧。再発防止として prefix を `terraform/tori-dev-blog` に変更
> 済み（[terraform/providers.tf](../../terraform/providers.tf)）。
> **同一GCPプロジェクトを複数リポジトリで共有する場合、GCS state prefixに
> リポジトリ名をフルで含めること。「terraform/blog」のような汎用名は禁止。**

> **既知の実インシデント（2026-07-23）**: PR #1 マージ後、CIが初回
> `terraform apply` を実行した際、GitHub Variable `CUSTOM_DOMAIN` が
> 未登録だったため `vars.CUSTOM_DOMAIN || ''` が空文字にフォールバック。
> `custom_domain != "" ? 1 : 0` を条件にした `cloudflare_record` /
> `google_firebase_hosting_custom_domain` が「不要」と判定され、稼働中の
> `preview.tori-dev.com` の DNS レコード・カスタムドメインが destroy
> された（`setup_gcp.sh` は GitHub **Secrets** だけ自動登録し、
> **Variables** は手動設定の想定のまま実際には登録し忘れていた）。
> `gh variable set CUSTOM_DOMAIN` で登録後、ワークフロー再実行で復旧。
> 再発防止として `setup_gcp.sh` が `FIREBASE_SITE_SUFFIX` /
> `CLOUDRUN_SERVICE_NAME` / `CUSTOM_DOMAIN` の GitHub Variables も
> Secrets と同様に自動登録するようにした。
> **Secrets と Variables は別画面・別APIなので、片方だけ自動化して
> 「初期構築完了」と判断しないこと。特に空文字がデフォルト値として
> 安全に倒れない（=リソースが消える方向に倒れる）変数は要注意。**

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
`backend "gcs" { prefix = "terraform/tori-dev-blog" }`）。

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
| `INDEXNOW_KEY` | `public/<key>.txt` のファイル名と同じ文字列。本番デプロイ後の IndexNow 通知（`scripts/submit-indexnow.mjs`）が使う。IndexNow の仕様上このキーは `https://tori-dev.com/<key>.txt` で公開されるため秘匿対象ではない（Secrets 管理は形式的） |

`INDEXNOW_KEY` をローテーションするときは、`public/<新key>.txt` の追加コミットと
`gh secret set INDEXNOW_KEY --body "<新key>"` を**同時に**行い、旧ファイルを消す。
片方だけ更新すると IndexNow 側の鍵検証が失敗するが、通知はデプロイを落とさない設計
（`continue-on-error` + スクリプト側も常に exit 0）なので CI は緑のまま止まる。
更新後の最初の本番デプロイで `Notify IndexNow` ステップのログに
`[indexnow] N 件 送信 (HTTP 200/202)` が出ていることを目視で確認する。

GitHub Variables（`vars`）— `setup_gcp.sh` が Secrets と同様に自動登録する:

| Variable | 値 | 備考 |
|---|---|---|
| `FIREBASE_SITE_SUFFIX` | `blog` | site_id = `tori-develop-blog` |
| `CLOUDRUN_SERVICE_NAME` | `tori-dev-blog` | 未使用（`deploy_target=firebase`） |
| `CUSTOM_DOMAIN` | `setup_gcp.sh` 実行時の `$CUSTOM_DOMAIN` 環境変数の値 | **空のまま実行すると登録されない**。この状態で `main` が push されると CI は `custom_domain=""` で apply し、DNSレコード/カスタムドメインを destroy する（上記2026-07-23インシデント参照）。カスタムドメイン運用時は必ず `CUSTOM_DOMAIN` を設定してから `setup_gcp.sh` を実行すること |

### 2.5. GitHub Environment（承認ゲート）の設定

`.github/workflows/firebase-hosting-deploy.yml` の `deploy` job は
`environment: production` を参照する。`main` への push だけで
`terraform apply -auto-approve` が本番GCPリソースを変更してしまうため
（過去に state 衝突で他リポジトリの本番リソースを誤破壊したインシデントの
教訓）、reviewer 承認を挟みたい場合は以下を GitHub の Web UI で設定する
（ワークフローYAML単体では有効化されない）:

1. リポジトリ `Settings > Environments > New environment` で `production` を作成
2. `Required reviewers` にレビュー担当者を追加
3. 必要に応じて `Deployment branches` を `main` のみに制限

設定しない場合、承認なしで即 apply される（現状の挙動と同じ）。

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
