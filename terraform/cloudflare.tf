# Firebase Hosting 用の DNS レコード
#
# apex(tori-dev.com) には DNS の仕様上 CNAME を張れないが、Cloudflare の
# CNAME フラットニング（apex では既定で有効）が CNAME を A に解決して応答するため、
# ここでは CNAME として宣言できる。
# proxied = false（DNS-only / グレークラウド）は必須:
#   - Firebase Hosting が自前の証明書でドメイン検証・TLS 終端するため、
#     プロキシすると証明書検証や 522 のトラブルが起きやすい
#   - Cloudflare の AI Crawl Control / Bot Fight Mode を経路に挟まないことで、
#     検索・AI クローラを意図せず遮断する事故を防ぐ

# 本番（apex）
resource "cloudflare_record" "firebase_hosting" {
  count = var.custom_domain != "" ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.custom_domain
  content = "${google_firebase_hosting_site.blog.site_id}.web.app"
  type    = "CNAME"
  proxied = false
  ttl     = 1

  comment = "main ブランチ -> 本番サイト"
}

# プレビュー（サブドメイン）
resource "cloudflare_record" "firebase_hosting_preview" {
  count = var.enable_preview_site && var.preview_custom_domain != "" ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.preview_custom_domain
  content = "${google_firebase_hosting_site.preview[0].site_id}.web.app"
  type    = "CNAME"
  proxied = false
  ttl     = 1

  comment = "preview ブランチ -> 検証サイト（noindex）"
}
