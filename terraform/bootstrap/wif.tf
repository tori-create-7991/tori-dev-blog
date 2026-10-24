# GitHub Actions から GCP へ鍵ファイルなしで入るための Workload Identity Federation。
# 命名ルール（gcp-ci-identity-naming）: 1 リポジトリ 1 Pool、Pool は <slug>-pool、Provider は github-actions。
# Pool がこのリポジトリ専用なので、SA のなりすまし条件を Environment・ブランチ・event_name だけで安全に絞れる。

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "${var.repo_slug}-pool"
  display_name              = "GitHub Actions (${var.github_repo})"
  description               = "GitHub Actions for ${local.repo_full_name}"

  depends_on = [google_project_service.this]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions"
  display_name                       = "GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
    "attribute.event_name" = "assertion.event_name"
    # deployer の判定用。Environment とブランチの組み合わせ（例 production@refs/heads/main）。
    # Environment を指定しないジョブのトークンには environment クレームが無いので、空ではなく none を入れる。
    "attribute.deploy_ctx" = "(has(assertion.environment) ? assertion.environment : \"none\") + \"@\" + assertion.ref"
    "attribute.actor"      = "assertion.actor"
  }

  # このリポジトリ以外のトークンは受け付けない。
  attribute_condition = "assertion.repository == \"${local.repo_full_name}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

locals {
  pool_principal = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}"
}
