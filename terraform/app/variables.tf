variable "project_id" {
  description = "GCP プロジェクト ID"
  type        = string
}

variable "region" {
  description = "GCP リージョン"
  type        = string
  default     = "asia-northeast1"
}

variable "prod_site_suffix" {
  description = "本番 Hosting サイトの接尾辞（site_id = <project_id>-<suffix>）"
  type        = string
  default     = "blog"
}

variable "preview_site_suffix" {
  description = "検証 Hosting サイトの接尾辞（site_id = <project_id>-<suffix>）"
  type        = string
  default     = "preview"
}

variable "custom_domain" {
  description = "本番の独自ドメイン（apex を想定）。空なら独自ドメインなしで *.web.app から配信する"
  type        = string
  default     = ""
}

# CI が GitHub Variables（bootstrap が登録した値）を渡し、tfvars と食い違っていないか確かめるための値。
# ローカル実行では空のまま（確認しない）。
variable "expected_prod_site_id" {
  description = "bootstrap が登録した本番サイト ID（CI が TF_VAR_ で渡す）"
  type        = string
  default     = ""
}

variable "expected_preview_site_id" {
  description = "bootstrap が登録した検証サイト ID（CI が TF_VAR_ で渡す）"
  type        = string
  default     = ""
}
