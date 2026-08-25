# Firebase Hosting サイト
#
# 環境を2つ持つ:
#   本番     site_id = ${project_id}-${firebase_site_suffix}   (例: tori-develop-blog)  ← main ブランチ
#   プレビュー site_id = ${project_id}-${preview_site_suffix}   (例: tori-develop-preview) ← preview ブランチ
#
# 旧 Nuxt2 サイトは default site (tori-develop) にそのまま残す。ここでは管理しない。

resource "google_firebase_hosting_site" "blog" {
  provider = google-beta
  project  = var.project_id
  site_id  = "${var.project_id}-${var.firebase_site_suffix}"

  depends_on = [
    google_firebase_project.default,
    google_project_service.firebasehosting,
  ]
}

resource "google_firebase_hosting_site" "preview" {
  count = var.enable_preview_site ? 1 : 0

  provider = google-beta
  project  = var.project_id
  site_id  = "${var.project_id}-${var.preview_site_suffix}"

  depends_on = [
    google_firebase_project.default,
    google_project_service.firebasehosting,
  ]
}

# 本番カスタムドメイン（apex を想定。設定時のみ）
resource "google_firebase_hosting_custom_domain" "blog" {
  count = var.custom_domain != "" ? 1 : 0

  provider      = google-beta
  project       = var.project_id
  site_id       = google_firebase_hosting_site.blog.site_id
  custom_domain = var.custom_domain

  wait_dns_verification = false
}

# プレビュー用カスタムドメイン
resource "google_firebase_hosting_custom_domain" "preview" {
  count = var.enable_preview_site && var.preview_custom_domain != "" ? 1 : 0

  provider      = google-beta
  project       = var.project_id
  site_id       = google_firebase_hosting_site.preview[0].site_id
  custom_domain = var.preview_custom_domain

  wait_dns_verification = false
}

output "firebase_hosting_site_id" {
  description = "本番 Firebase HostingサイトID"
  value       = google_firebase_hosting_site.blog.site_id
}

output "firebase_hosting_default_url" {
  description = "本番 Firebase HostingデフォルトURL"
  value       = "https://${google_firebase_hosting_site.blog.site_id}.web.app"
}

output "firebase_preview_site_id" {
  description = "プレビュー Firebase HostingサイトID"
  value       = var.enable_preview_site ? google_firebase_hosting_site.preview[0].site_id : ""
}

output "firebase_preview_default_url" {
  description = "プレビュー Firebase HostingデフォルトURL"
  value       = var.enable_preview_site ? "https://${google_firebase_hosting_site.preview[0].site_id}.web.app" : ""
}
