# tori-dev.com の設定値（秘密は含まない）。フォークした場合は terraform.tfvars.example から作り直す。
project_id   = "tori-develop"
region       = "asia-northeast1"
github_owner = "tori-create-7991"
github_repo  = "tori-dev-blog"
repo_slug    = "tori-dev-blog"

tf_state_bucket          = "tori-develop-tfstate"
tf_state_bucket_location = "US-CENTRAL1" # 既存バケットの実際の値（変えると作り直しになる）
app_state_prefix         = "terraform/tori-dev-blog"

prod_site_suffix    = "blog"
preview_site_suffix = "preview"
custom_domain       = "tori-dev.com"
indexnow_key        = "ea9a6ed0baf202d98cdb250aaa6d881d" # public/<key>.txt と同じ

enable_cloudflare  = true
cloudflare_zone_id = "98c94cbaea7f571a226692e1a14eba27"

# 2026-10 の移行で既存リソースを取り込む。移行後も残しておいてよい（取り込み済みなら何もしない）。
existing = {
  import_state_bucket = true
  import_services = [
    "cloudresourcemanager.googleapis.com",
    "firebase.googleapis.com",
    "firebasehosting.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
  ]
  dns_apex_a_record_id        = "15048a15c7e4d915cdefb914566da18c"
  dns_ownership_txt_record_id = "4c16c230ab3f423c05eb15f0a103019c"
}
