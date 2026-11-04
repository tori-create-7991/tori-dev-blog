# 既存リソースの取り込み。terraform.tfvars の `existing` に値があるものだけ動く。
# フォークして新しく作る場合は、gcloud で作った tfstate バケットだけ import する
# （import_state_bucket = true）。

import {
  for_each = var.existing.import_state_bucket ? toset([var.tf_state_bucket]) : toset([])
  to       = google_storage_bucket.tfstate
  id       = each.value
}

import {
  for_each = toset(var.existing.import_services)
  to       = google_project_service.this[each.value]
  id       = "${var.project_id}/${each.value}"
}

import {
  for_each = var.existing.dns_apex_a_record_id != "" ? toset([var.existing.dns_apex_a_record_id]) : toset([])
  to       = cloudflare_dns_record.apex_a[0]
  id       = "${var.cloudflare_zone_id}/${each.value}"
}

import {
  for_each = var.existing.dns_ownership_txt_record_id != "" ? toset([var.existing.dns_ownership_txt_record_id]) : toset([])
  to       = cloudflare_dns_record.ownership_txt[0]
  id       = "${var.cloudflare_zone_id}/${each.value}"
}

# GitHub の設定。リポジトリに既にある場合（GCP プロジェクトを移したときなど）に取り込む。
# 取り込んだあと、値は新しいプロジェクトのものに更新される。
import {
  for_each = var.existing.import_github_settings ? toset(keys(local.actions_variables)) : toset([])
  to       = github_actions_variable.this[each.value]
  id       = "${var.github_repo}:${each.value}"
}

import {
  for_each = var.existing.import_github_settings ? toset(["production"]) : toset([])
  to       = github_repository_environment.production
  id       = "${var.github_repo}:${each.value}"
}

import {
  for_each = var.existing.import_github_settings ? toset(["pr-preview"]) : toset([])
  to       = github_repository_environment.pr_preview
  id       = "${var.github_repo}:${each.value}"
}

import {
  for_each = var.existing.production_branch_policy_id != "" ? toset([var.existing.production_branch_policy_id]) : toset([])
  to       = github_repository_environment_deployment_policy.production_main
  id       = "${var.github_repo}:production:${each.value}"
}

import {
  for_each = var.existing.main_ruleset_id != "" ? toset([var.existing.main_ruleset_id]) : toset([])
  to       = github_repository_ruleset.main
  id       = "${var.github_repo}:${each.value}"
}
