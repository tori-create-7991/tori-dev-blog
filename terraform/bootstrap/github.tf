# GitHub リポジトリの設定。CI はここで登録した Variables だけを読み、Secrets は使わない。
# 認証はローカルの GITHUB_TOKEN=$(gh auth token)。

locals {
  actions_variables = {
    GCP_PROJECT_ID      = var.project_id
    GCP_REGION          = var.region
    WIF_PROVIDER        = google_iam_workload_identity_pool_provider.github.name
    DEPLOYER_SA         = google_service_account.deployer.email
    PREVIEW_SA          = google_service_account.preview.email
    PLANNER_SA          = google_service_account.planner.email
    TF_STATE_BUCKET     = google_storage_bucket.tfstate.name
    TF_STATE_PREFIX_APP = var.app_state_prefix
    PROD_SITE_ID        = local.prod_site_id
    PREVIEW_SITE_ID     = local.preview_site_id
    PROD_SITE_URL       = local.prod_site_url
    INDEXNOW_KEY        = var.indexnow_key
  }
}

resource "github_actions_variable" "this" {
  for_each = local.actions_variables

  repository    = var.github_repo
  variable_name = each.key
  value         = each.value
}

# main へのマージ後に動く本番用の Environment。main 以外からは使えない。
resource "github_repository_environment" "production" {
  repository  = var.github_repo
  environment = "production"

  deployment_branch_policy {
    protected_branches     = false
    custom_branch_policies = true
  }
}

resource "github_repository_environment_deployment_policy" "production_main" {
  repository     = var.github_repo
  environment    = github_repository_environment.production.environment
  branch_pattern = "main"
}

# PR プレビュー用の Environment。
resource "github_repository_environment" "pr_preview" {
  repository  = var.github_repo
  environment = "pr-preview"
}

# main の保護。PR 必須、build と plan の成功が必須。
# 管理者は保護を無視してマージできる（フォークや Dependabot の PR では plan が動かないため）。
resource "github_repository_ruleset" "main" {
  name        = "main"
  repository  = var.github_repo
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  bypass_actors {
    actor_id    = 5 # RepositoryRole: admin
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count = 0
    }

    required_status_checks {
      required_check {
        context = "build"
      }
      required_check {
        context = "plan"
      }
    }
  }
}

# 非公開の脆弱性報告（SECURITY.md から案内する）。provider にリソースが無いので gh CLI で設定する。
resource "terraform_data" "private_vulnerability_reporting" {
  count = var.enable_private_vulnerability_reporting ? 1 : 0

  triggers_replace = [local.repo_full_name]

  provisioner "local-exec" {
    command = "gh api -X PUT repos/${local.repo_full_name}/private-vulnerability-reporting --silent"
  }
}
