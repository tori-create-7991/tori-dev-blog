locals {
  repo_full_name  = "${var.github_owner}/${var.github_repo}"
  prod_site_id    = "${var.project_id}-${var.prod_site_suffix}"
  preview_site_id = "${var.project_id}-${var.preview_site_suffix}"
  # 所有権 TXT が指すサイト。移行中だけ旧サイトに向ける（variables.tf の dns_ownership_site_id）
  ownership_site_id = var.dns_ownership_site_id != "" ? var.dns_ownership_site_id : local.prod_site_id
  prod_site_url     = var.custom_domain != "" ? "https://${var.custom_domain}" : "https://${local.prod_site_id}.web.app"
}
