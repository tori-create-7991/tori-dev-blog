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
