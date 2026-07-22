# Firebase Hosting サイト
resource "google_firebase_hosting_site" "blog" {
  provider = google-beta
  project  = var.project_id
  site_id  = "${var.project_id}-${var.firebase_site_suffix}"

  depends_on = [
    google_firebase_project.default,
    google_project_service.firebasehosting,
  ]
}

# カスタムドメイン（設定時のみ）
resource "google_firebase_hosting_custom_domain" "blog" {
  count = var.custom_domain != "" ? 1 : 0

  provider      = google-beta
  project       = var.project_id
  site_id       = google_firebase_hosting_site.blog.site_id
  custom_domain = var.custom_domain

  wait_dns_verification = false
}

output "firebase_hosting_site_id" {
  description = "Firebase HostingサイトID"
  value       = google_firebase_hosting_site.blog.site_id
}

output "firebase_hosting_default_url" {
  description = "Firebase HostingデフォルトURL"
  value       = "https://${google_firebase_hosting_site.blog.site_id}.web.app"
}
