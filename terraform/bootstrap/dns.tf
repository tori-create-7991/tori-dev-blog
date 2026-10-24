# 独自ドメインの DNS（Cloudflare）。enable_cloudflare = true のときだけ作る。
#
# - すべて DNS only（proxied = false）。Firebase Hosting が自前の証明書で TLS を終端するため。
#   このため Cloudflare の Bot 対策や AI クローラ設定は効かないので管理しない。
# - DNS はめったに変わらないので CI ではなくこの stack に置き、CI に Cloudflare トークンを持たせない。
# - ゾーン内のほかのレコード（メールなど）はこのリポジトリでは管理しない。

# apex の A レコード。Firebase Hosting は IP ではなく Host ヘッダでサイトを振り分けるので、
# 配信先サイトの切り替えは app stack のカスタムドメインの紐付けで行い、このレコードは変えない。
resource "cloudflare_dns_record" "apex_a" {
  count = var.enable_cloudflare && var.custom_domain != "" ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.custom_domain
  type    = "A"
  content = var.firebase_hosting_ip
  ttl     = 1
  proxied = false
  # comment は付けない（Terraform 導入前からある既存レコードの状態に合わせる）

  lifecycle {
    prevent_destroy = true # 消すと tori-dev.com の名前解決が止まる
  }
}

# Firebase Hosting のサイト所有権。apex をこのサイトに紐付けるために要る。
resource "cloudflare_dns_record" "ownership_txt" {
  count = var.enable_cloudflare && var.custom_domain != "" ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = var.custom_domain
  type    = "TXT"
  content = "hosting-site=${local.prod_site_id}"
  ttl     = 1
  proxied = false
  comment = "Firebase Hosting サイト所有権（apex -> 本番サイト）"

  lifecycle {
    prevent_destroy = true # 消すと独自ドメインの所有権確認が外れる
  }
}
