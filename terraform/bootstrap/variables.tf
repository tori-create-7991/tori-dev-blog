variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "region" {
  description = "GCP リージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "github_owner" {
  description = "GitHub のユーザー名または組織名"
  type        = string
}

variable "github_repo" {
  description = "GitHub リポジトリ名（owner を除く）"
  type        = string
}

variable "repo_slug" {
  description = <<-EOT
    WIF Pool・SA の名前に使う短い名前。命名ルール（gcp-ci-identity-naming）では、
    リポジトリ名を小文字にし `_` と `.` を `-` に置き換えたもの。
    Pool は <slug>-pool（4〜32 文字）、SA は gha-<slug>-<役割>（6〜30 文字）になる。
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.repo_slug)) && length("gha-${var.repo_slug}-deployer") <= 30 && length("${var.repo_slug}-pool") <= 32
    error_message = "repo_slug は英小文字・数字・- だけで、gha-<slug>-deployer が 30 文字以内、<slug>-pool が 32 文字以内になる長さにしてください。"
  }
}

variable "tf_state_bucket" {
  description = "tfstate を置く GCS バケット名（最初の 1 回だけ gcloud で作り、import する）"
  type        = string
}

variable "tf_state_bucket_location" {
  description = "tfstate バケットのロケーション。既存バケットを import する場合は実際の値に合わせる（違うと作り直しになる）"
  type        = string
  default     = "ASIA-NORTHEAST1"
}

variable "app_state_prefix" {
  description = "app stack の state の prefix（terraform/app/backend.hcl と同じ値）"
  type        = string
}

variable "prod_site_suffix" {
  description = "本番 Hosting サイトの接尾辞（app stack と同じ値）"
  type        = string
  default     = "blog"
}

variable "preview_site_suffix" {
  description = "検証 Hosting サイトの接尾辞（app stack と同じ値）"
  type        = string
  default     = "preview"
}

variable "custom_domain" {
  description = "本番の独自ドメイン（apex）。空なら *.web.app で配信"
  type        = string
  default     = ""
}

variable "indexnow_key" {
  description = "IndexNow のキー（public/<key>.txt と同じ文字列。公開値なので秘密ではない）。空なら通知しない"
  type        = string
  default     = ""
}

variable "enable_cloudflare" {
  description = "独自ドメインの DNS を Cloudflare で管理するか"
  type        = bool
  default     = false
}

variable "cloudflare_zone_id" {
  description = "Cloudflare のゾーン ID（秘密ではない）。enable_cloudflare = true のとき必須"
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_cloudflare || can(regex("^[0-9a-f]{32}$", var.cloudflare_zone_id))
    error_message = "enable_cloudflare = true のときは cloudflare_zone_id に 32 桁の 16 進数のゾーン ID を入れてください。"
  }
}

variable "firebase_hosting_ip" {
  description = "apex の A レコードに入れる Firebase Hosting の IP"
  type        = string
  default     = "199.36.158.100"
}

variable "enable_private_vulnerability_reporting" {
  description = "GitHub の非公開の脆弱性報告を有効にするか（gh CLI で設定する）"
  type        = bool
  default     = true
}

# 既存リソースを取り込むための ID。新しく作る場合（フォークなど）は空のままにする。
variable "existing" {
  description = "import する既存リソース。値があるものだけ import ブロックが動く"
  type = object({
    import_state_bucket         = optional(bool, false)
    import_services             = optional(list(string), [])
    dns_apex_a_record_id        = optional(string, "")
    dns_ownership_txt_record_id = optional(string, "")
  })
  default = {}

  validation {
    condition = (
      (var.existing.dns_apex_a_record_id == "" && var.existing.dns_ownership_txt_record_id == "")
      || (var.enable_cloudflare && var.custom_domain != "")
    )
    error_message = "DNS レコードを import するには enable_cloudflare = true と custom_domain が必要です。"
  }
}
