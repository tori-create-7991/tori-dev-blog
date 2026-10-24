# Firebase Hosting サイト
#
#   本番     site_id = ${project_id}-${prod_site_suffix}     main ブランチから配信
#   検証     site_id = ${project_id}-${preview_site_suffix}  PR ごとのプレビューチャネル（pr-<番号>）の置き場。noindex
#
# 検証サイトには独自ドメインを付けない。PR ごとに
# https://<preview site id>--pr-<番号>-<hash>.web.app の URL が発行される。
# GCP プロジェクトの default site（サイト ID = project_id）は旧 Nuxt2 サイト。削除できないので管理しない。

resource "google_firebase_hosting_site" "blog" {
  provider = google-beta
  project  = var.project_id
  site_id  = "${var.project_id}-${var.prod_site_suffix}"

  depends_on = [google_firebase_project.default]

  lifecycle {
    # 本番サイトは消さない（設定値の書き換えミスで作り直しにならないようにする）
    prevent_destroy = true

    # app の tfvars と bootstrap（DNS の所有権 TXT・CI の Variables）の値が食い違っていたら止める
    precondition {
      condition     = var.expected_prod_site_id == "" || var.expected_prod_site_id == "${var.project_id}-${var.prod_site_suffix}"
      error_message = "本番サイト ID が bootstrap の値（GitHub Variables の PROD_SITE_ID）と違います。terraform/app/terraform.tfvars と terraform/bootstrap/terraform.tfvars を揃えてください。"
    }
  }
}

resource "google_firebase_hosting_site" "preview" {
  provider = google-beta
  project  = var.project_id
  site_id  = "${var.project_id}-${var.preview_site_suffix}"

  depends_on = [google_firebase_project.default]

  lifecycle {
    precondition {
      condition     = var.expected_preview_site_id == "" || var.expected_preview_site_id == "${var.project_id}-${var.preview_site_suffix}"
      error_message = "検証サイト ID が bootstrap の値（GitHub Variables の PREVIEW_SITE_ID）と違います。両方の terraform.tfvars を揃えてください。"
    }
  }
}

# 旧定義では enable_preview_site で count を付けていた。検証サイトは PR プレビューに必須なので常に作る。
moved {
  from = google_firebase_hosting_site.preview[0]
  to   = google_firebase_hosting_site.preview
}

# 本番の独自ドメイン（任意）。DNS レコードは bootstrap stack が管理する。
resource "google_firebase_hosting_custom_domain" "blog" {
  count = var.custom_domain != "" ? 1 : 0

  provider      = google-beta
  project       = var.project_id
  site_id       = google_firebase_hosting_site.blog.site_id
  custom_domain = var.custom_domain

  wait_dns_verification = false

  lifecycle {
    prevent_destroy = true
  }
}

output "prod_site_id" {
  description = "本番 Firebase Hosting サイト ID"
  value       = google_firebase_hosting_site.blog.site_id
}

output "prod_default_url" {
  description = "本番 Firebase Hosting の既定 URL"
  value       = "https://${google_firebase_hosting_site.blog.site_id}.web.app"
}

output "preview_site_id" {
  description = "検証 Firebase Hosting サイト ID（PR プレビューのチャネルを置く）"
  value       = google_firebase_hosting_site.preview.site_id
}
