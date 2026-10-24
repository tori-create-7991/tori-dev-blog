# フォークして自分の環境に構築する

このリポジトリをフォークし、自分の GCP プロジェクトと GitHub で同じ構成（Firebase Hosting で配信、
PR ごとのプレビュー、Terraform によるインフラ管理）を作る手順。構成の考え方は
[ADR 0006](../adr/0006-two-stage-terraform.md)。

必須なのは GCP と GitHub だけ。独自ドメインと Cloudflare は任意で、無ければ `*.web.app` で配信する。

## 0. 前提

- GCP プロジェクト（課金を有効にしたもの）と、そのオーナー権限を持つ gcloud のアカウント
- GitHub のフォーク（管理者権限）と `gh` CLI
- `mise`（このリポジトリの Terraform と gcloud はこれで入れる想定）、Node.js 22

```bash
gcloud auth login
gh auth login
export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)"   # 1 時間で切れる
export GITHUB_TOKEN="$(gh auth token)"
```

## 1. tfstate バケットを作る（1 回だけ）

Terraform の state を置く場所が先に要るので、これだけは gcloud で作る。次の手順で bootstrap が import して、以降は Terraform で管理する。

```bash
gcloud storage buckets create gs://<project-id>-tfstate \
  --project=<project-id> --location=asia-northeast1 \
  --uniform-bucket-level-access --public-access-prevention
```

## 2. 設定値を書き換える

| ファイル | 書き換える値 |
|---|---|
| `terraform/bootstrap/terraform.tfvars` | `terraform.tfvars.example` をコピーして全部（project_id、github_owner、github_repo、repo_slug、バケット名など） |
| `terraform/bootstrap/backend.hcl` | `bucket` と `prefix`（`terraform/<リポジトリ名>/bootstrap`） |
| `terraform/app/terraform.tfvars` | `terraform.tfvars.example` をコピーして全部 |
| `terraform/app/backend.hcl` | `bucket` と `prefix`（`terraform/<リポジトリ名>`。bootstrap の `app_state_prefix` と同じ） |

- 名前は 00_my_env の命名ルール（`gcp-ci-identity-naming`）に合わせて、リポジトリ名から決まる。`repo_slug` はリポジトリ名を小文字にし、`_` と `.` を `-` にしたもの。
- `existing` は `import_state_bucket = true` だけにする（手順 1 で作ったバケットを取り込む）。
- 独自ドメインを使わないなら `custom_domain = ""`、`enable_cloudflare = false`。

## 3. bootstrap を apply

```bash
mise exec -- terraform -chdir=terraform/bootstrap init -backend-config=backend.hcl
mise exec -- terraform -chdir=terraform/bootstrap apply
```

API の有効化、専用の WIF Pool と CI 用 SA、GitHub の Variables・Environment・main の保護ルールができる。

Cloudflare を使う場合（`enable_cloudflare = true`）は、DNS を編集できる API トークンを環境変数 `CLOUDFLARE_API_TOKEN` に入れてから実行する。
発行用トークン（User API Tokens: Edit 権限）を Secret Manager に置いて `scripts/with-cloudflare-token.sh` を使えば、
実行のたびに有効期限 1 時間のトークンを発行して終わったら消せる（`CF_ISSUER_SECRET`・`CF_ISSUER_PROJECT` で secret の場所を指定）。

```bash
CF_ISSUER_SECRET=<secret 名> CF_ISSUER_PROJECT=<GCP プロジェクト> \
  scripts/with-cloudflare-token.sh -- mise exec -- terraform -chdir=terraform/bootstrap apply
```

## 4. app を apply（初回だけローカルで）

初回は Firebase の有効化（`google_firebase_project`）を含むので、CI の SA ではなく自分の権限で実行する。2 回目以降は CI が main への push で apply する。

```bash
mise exec -- terraform -chdir=terraform/app init -backend-config=backend.hcl
mise exec -- terraform -chdir=terraform/app apply
```

独自ドメインを使う場合は、Firebase Console の Hosting で本番サイトのドメインの状態が「接続済み」になるまで待つ（DNS は bootstrap が作っている）。

## 5. サイトの中身を自分のものにする

インフラとは別に、次はフォークした人が書き換える。

| 場所 | 内容 |
|---|---|
| `siteConfig.ts` | サイト名・著者・メニュー・SNS |
| `content/` | 記事・作品・サービス・プロフィール（**記事と画像は All Rights Reserved**。[content-license.md](../content-license.md)） |
| `public/` | 画像、`llms.txt`、IndexNow のキーファイル（`<key>.txt`。使うなら bootstrap の `indexnow_key` と同じ名前にする） |
| `scripts/build-og-images.py` | OG 画像に入るサイト名と著者名 |
| `nuxt.config.ts` | `siteUrl` の既定値 |

## 6. push して動かす

PR を作ると `build`（ビルドとプレビュー配信）と `plan`（app の plan）が動き、PR にプレビュー URL と plan の結果がコメントされる。
マージすると `terraform`（app の apply）と `deploy`（本番配信）が動く。

## 運用の決まり

- **インフラの変更**: app（Hosting・ドメイン）は PR で変えれば、マージ時に CI が apply する。
  bootstrap（権限・DNS・GitHub 設定）はローカルで plan → PR → マージ後にローカルで apply。
- **フォークと Dependabot の PR**: GCP に認証できないので plan とプレビューは動かず、ビルドの確認だけになる。
  必須チェック `plan` は成功扱いになるので、Terraform に関わる更新はローカルで plan を確認してから、
  管理者として保護を無視してマージする。
- **CI は秘密を持たない**: GitHub Secrets は使わない。値はすべて bootstrap が登録する Variables。
- 詳しい運用手順は [terraform-deploy.md](../runbook/terraform-deploy.md)。
