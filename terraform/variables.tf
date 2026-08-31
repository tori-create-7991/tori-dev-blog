variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "region" {
  description = "GCPリージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "github_repo" {
  description = "GitHubリポジトリ（owner/repo形式）"
  type        = string
}

variable "deploy_target" {
  description = "デプロイ先（firebase / cloudrun / both）"
  type        = string
  default     = "firebase"

  validation {
    condition     = contains(["firebase", "cloudrun", "both"], var.deploy_target)
    error_message = "deploy_targetはfirebase, cloudrun, bothのいずれかを指定してください。"
  }
}

variable "firebase_site_suffix" {
  description = "Firebase Hostingサイト接尾辞（site_id = project_id-suffix）"
  type        = string
  default     = "blog"
}

variable "cloudrun_service_name" {
  description = "Cloud Runサービス名"
  type        = string
  default     = "tori-dev-blog"
}

variable "custom_domain" {
  description = "本番カスタムドメイン（apex 想定。空=設定なし）"
  type        = string
  default     = ""
}

variable "preview_site_suffix" {
  description = "プレビュー用 Firebase Hosting サイト接尾辞（site_id = project_id-suffix）"
  type        = string
  default     = "preview"
}

variable "preview_custom_domain" {
  description = "プレビュー用カスタムドメイン（空=設定なし）"
  type        = string
  default     = ""
}

variable "manage_apex_dns" {
  description = <<-EOT
    apex(custom_domain)の DNS レコードを Terraform で管理するか。

    既定は false。apex には Terraform 導入前から手動の A レコード
    (Firebase 共通IP 199.36.158.100)が存在し、これを CNAME に置き換えると
    タイプ変更のため destroy→create になり、一時的に名前解決が落ちる。
    Firebase は IP ではなく Host ヘッダでサイトを振り分けるため、
    A レコードは据え置いたまま google_firebase_hosting_custom_domain の
    紐付けを変えるだけで配信先を切り替えられる。
  EOT
  type        = bool
  default     = false
}

variable "enable_preview_site" {
  description = "プレビュー環境（別 Hosting サイト + ドメイン）を作るか"
  type        = bool
  default     = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare APIトークン（カスタムドメイン未使用時は省略可）"
  type        = string
  sensitive   = true
  default     = "dummy_not_used_without_custom_domain_pad" # 40文字ダミー（provider初期化用）
}

variable "cloudflare_zone_id" {
  description = "CloudflareゾーンID（カスタムドメイン未使用時は空でOK）"
  type        = string
  default     = ""
}
