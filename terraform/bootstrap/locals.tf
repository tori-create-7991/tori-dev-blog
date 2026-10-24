locals {
  repo_full_name  = "${var.github_owner}/${var.github_repo}"
  prod_site_id    = "${var.project_id}-${var.prod_site_suffix}"
  preview_site_id = "${var.project_id}-${var.preview_site_suffix}"
  prod_site_url   = var.custom_domain != "" ? "https://${var.custom_domain}" : "https://${local.prod_site_id}.web.app"
}
