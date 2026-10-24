# bootstrap stack: 人がローカルで apply する（初回と、権限・GitHub 設定・DNS を変えるとき）。
#
# 認証:
#   GCP        GOOGLE_OAUTH_ACCESS_TOKEN=$(gcloud auth print-access-token) など、自分のアカウント
#   GitHub     GITHUB_TOKEN=$(gh auth token)
#   Cloudflare enable_cloudflare = true のときだけ。scripts/with-cloudflare-token.sh が
#              1 時間有効のトークンを発行して CLOUDFLARE_API_TOKEN に入れる
#
# CI からは実行しない。CI 用の SA にはこの stack を変更する権限を与えていない。

terraform {
  required_version = ">= 1.7.0" # import ブロックの for_each を使う

  # bucket と prefix は backend.hcl で渡す。prefix にはリポジトリ名をフルで含めること。
  backend "gcs" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.8"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.28"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "github" {
  owner = var.github_owner
}

# トークンは環境変数 CLOUDFLARE_API_TOKEN から読む。
# enable_cloudflare = false ならリソースが 0 件なので、トークンが無くても動く。
provider "cloudflare" {}
