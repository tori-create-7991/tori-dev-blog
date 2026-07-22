# Firebase Hosting用のDNSレコード（カスタムドメイン設定時のみ）
resource "cloudflare_record" "firebase_hosting" {
  count = var.custom_domain != "" ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.custom_domain
  content = "${google_firebase_hosting_site.blog.site_id}.web.app"
  type    = "CNAME"
  proxied = false
  ttl     = 1
}
