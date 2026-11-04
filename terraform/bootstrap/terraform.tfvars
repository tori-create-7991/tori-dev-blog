# tori-dev.com の設定値（秘密は含まない）。フォークした場合は terraform.tfvars.example から作り直す。
project_id   = "tori-dev-sites"
region       = "asia-northeast1"
github_owner = "tori-create-7991"
github_repo  = "tori-dev-blog"
repo_slug    = "tori-dev-blog"

# 1 リポジトリ 1 バケット（<project_id>-<repo_slug>-tfstate）。最初の 1 回だけ gcloud で作って import する。
tf_state_bucket          = "tori-dev-sites-tori-dev-blog-tfstate"
tf_state_bucket_location = "US-CENTRAL1" # Cloud Storage の Always Free の対象リージョン
app_state_prefix         = "terraform/tori-dev-blog/app"

prod_site_suffix    = "blog"
preview_site_suffix = "preview"
custom_domain       = "tori-dev.com"
indexnow_key        = "ea9a6ed0baf202d98cdb250aaa6d881d" # public/<key>.txt と同じ

enable_cloudflare  = true
cloudflare_zone_id = "98c94cbaea7f571a226692e1a14eba27"

# tori-develop から tori-dev-sites への移行中だけ使う。所有権 TXT を旧サイトに向けたままにして、
# 新サイトの準備ができるまで tori-dev.com を旧サイトから配信する。
# 切替（docs/runbook/move-to-tori-dev-sites.md の手順 5）でこの行を消して apply する。
dns_ownership_site_id = "tori-develop-blog"

# 既存リソースの取り込み。取り込み済みなら何もしないので、移行後も残しておいてよい。
existing = {
  import_state_bucket = true

  # GitHub の設定（移行前から tori-develop 向けに作ってあったもの。値は apply で新プロジェクトのものに変わる）
  import_github_settings      = true
  production_branch_policy_id = "64191645"
  main_ruleset_id             = "25779873"

  # Cloudflare のレコード（2026-10 から Terraform 管理）
  dns_apex_a_record_id        = "15048a15c7e4d915cdefb914566da18c"
  dns_ownership_txt_record_id = "4c16c230ab3f423c05eb15f0a103019c"
}
