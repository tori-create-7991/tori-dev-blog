# Firebase Hosting サイト
#
#   本番     site_id = ${project_id}-${prod_site_suffix}     main ブランチから配信
#   検証     site_id = ${project_id}-${preview_site_suffix}  PR ごとのプレビューチャネル（pr-<番号>）の置き場。noindex
#
# 検証サイトには独自ドメインを付けない。PR ごとに
# https://<preview site id>--pr-<番号>-<hash>.web.app の URL が発行される。
# GCP プロジェクトの default site（tori-develop）は旧 Nuxt2 サイト。削除できないので管理しない。

resource "google_firebase_hosting_site" "blog" {
  provider = google-beta
  project  = var.project_id
  site_id  = "${var.project_id}-${var.prod_site_suffix}"

  depends_on = [google_firebase_project.default]
}

resource "google_firebase_hosting_site" "preview" {
  provider = google-beta
  project  = var.project_id
  site_id  = "${var.project_id}-${var.preview_site_suffix}"

  depends_on = [google_firebase_project.default]
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
