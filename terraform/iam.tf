# プロジェクト番号を取得（WIF Pool のバインディングに必要）
data "google_project" "current" {
  project_id = var.project_id
}

# WIF Pool は共有リソース（business-cardリポジトリ等と共用）
# setup_gcp.sh の gcloud コマンドで確保済み。
locals {
  wif_pool_id   = "github-pool"
  wif_pool_name = "projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/github-pool"

  sa_roles = [
    "roles/firebase.admin",
    "roles/run.admin",
    "roles/artifactregistry.admin",
    "roles/iam.serviceAccountUser",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/storage.admin",
    # 以下3つはCI terraform apply がIAM/WIF/SAリソースを管理するために必要
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/iam.serviceAccountAdmin",
  ]
}

# このリポジトリ専用のOIDC Provider（Pool内でID一意にする）
resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = local.wif_pool_id
  workload_identity_pool_provider_id = "tori-dev-blog-provider"
  display_name                       = "GitHub Provider (tori-dev-blog)"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
    "attribute.aud"        = "assertion.aud"
  }

  attribute_condition = "assertion.repository == \"${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Service Account for GitHub Actions
resource "google_service_account" "github_actions" {
  account_id   = "github-actions-tori-blog"
  display_name = "GitHub Actions tori-dev-blog Deploy"
  description  = "Service Account for tori-dev-blog GitHub Actions CI/CD"

  depends_on = [google_project_service.iam]
}

# IAMロール付与
resource "google_project_iam_member" "github_actions" {
  for_each = toset(local.sa_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# WIF → SA impersonation
resource "google_service_account_iam_member" "wif_sa_binding" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${local.wif_pool_name}/attribute.repository/${var.github_repo}"
}

# Outputs
output "wif_provider" {
  description = "WIFプロバイダの完全名（GitHub Secretsに設定）"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "sa_email" {
  description = "SAのメールアドレス（GitHub Secretsに設定）"
  value       = google_service_account.github_actions.email
}
