terraform {
  # 重要: このprefixは同一GCSバケット(${project_id}-tfstate)を共有する
  # 他リポジトリのterraform stateと絶対に衝突させないこと。
  # 過去に prefix="terraform/blog" が旧Nuxt3ブログリポジトリ
  # (012_nuxt-07_nuxt3_toriblog) の稼働中stateと衝突し、
  # 本番のService Account権限・WIF Provider・Artifact Registryを
  # 誤って破壊した実インシデントがある。
  # prefixにはリポジトリ名をフルで含めること（"terraform/blog"のような
  # 汎用名は禁止）。
  backend "gcs" {
    prefix = "terraform/tori-dev-blog"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project               = var.project_id
  region                = var.region
  user_project_override = true
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
