# Firebase Hosting サイト
#
#   本番     site_id = ${project_id}-${prod_site_suffix}     main ブランチから配信
#   検証     site_id = ${project_id}-${preview_site_suffix}  PR ごとのプレビューチャネル（pr-<番号>）の置き場。noindex
#
# 検証サイトには独自ドメインを付けない。PR ごとに
# https://<preview site id>--pr-<番号>-<hash>.web.app の URL が発行される。
# プロジェクトの default site（サイト ID = project_id）は使わない。削除できないので管理しない。

resource "google_firebase_hosting_site" "blog" {
  provider = google-beta
  project  = var.project_id
  site_id  = "${var.project_id}-${var.prod_site_suffix}"


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


  lifecycle {
    precondition {
      condition     = var.expected_preview_site_id == "" || var.expected_preview_site_id == "${var.project_id}-${var.preview_site_suffix}"
      error_message = "検証サイト ID が bootstrap の値（GitHub Variables の PREVIEW_SITE_ID）と違います。両方の terraform.tfvars を揃えてください。"
    }
  }
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

# 独自ドメインに必要な DNS の変更（所有権 TXT・証明書用の _acme-challenge TXT など）。
# 移行やドメインの付け替えのときに、Cloudflare に足すレコードをここで確かめる。
output "custom_domain_dns_updates" {
  description = "独自ドメインの DNS で必要な変更（Firebase が返す値）"
  value = length(google_firebase_hosting_custom_domain.blog) == 0 ? null : {
    ownership_state      = google_firebase_hosting_custom_domain.blog[0].ownership_state
    host_state           = google_firebase_hosting_custom_domain.blog[0].host_state
    cert                 = google_firebase_hosting_custom_domain.blog[0].cert
    required_dns_updates = google_firebase_hosting_custom_domain.blog[0].required_dns_updates
  }
}

output "preview_site_id" {
  description = "検証 Firebase Hosting サイト ID（PR プレビューのチャネルを置く）"
  value       = google_firebase_hosting_site.preview.site_id
}
