# CI 用の SA。役割ごとに分け、それぞれ必要な権限だけを持つ。
# 命名ルール: gha-<slug>-<役割>。
#
#   deployer  main ブランチ上の Environment production のジョブのみ。app の apply と本番配信
#   preview   PR のみ。検証サイトのプレビューチャネルへの配信
#   planner   Pool 内の全員（= このリポジトリの全ワークフロー）。読み取りだけ（plan・ズレ検知）
#
# Hosting の権限はプロジェクト単位でしか付けられないため、preview SA でも本番サイトへ
# 配信できてしまう。使えるのが「このリポジトリからの PR」だけで、PR を作れるのは
# 書き込み権限のある人だけなので許容する。

resource "google_service_account" "deployer" {
  account_id   = "gha-${var.repo_slug}-deployer"
  display_name = "GitHub Actions deployer (${var.github_repo})"
  description  = "main ブランチの CI。app stack の apply と本番配信"

  depends_on = [google_project_service.this]
}

resource "google_service_account" "preview" {
  account_id   = "gha-${var.repo_slug}-preview"
  display_name = "GitHub Actions preview (${var.github_repo})"
  description  = "PR の CI。プレビューチャネルへの配信だけ"

  depends_on = [google_project_service.this]
}

resource "google_service_account" "planner" {
  account_id   = "gha-${var.repo_slug}-planner"
  display_name = "GitHub Actions planner (${var.github_repo})"
  description  = "PR の plan と週 1 回のズレ検知。読み取りだけ"

  depends_on = [google_project_service.this]
}

# どのワークフローがどの SA になりすませるか。
# deployer は「Environment production を指定した、main ブランチ上のジョブ」だけ。
# Environment とブランチの両方を見るので、GitHub 側の Environment のブランチ制限が外れても main 以外からは使えず、
# main 上でも Environment を指定しない workflow からは使えない。
resource "google_service_account_iam_member" "deployer_wif" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "${local.pool_principal}/attribute.deploy_ctx/production@refs/heads/main"
}

resource "google_service_account_iam_member" "preview_wif" {
  service_account_id = google_service_account.preview.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "${local.pool_principal}/attribute.event_name/pull_request"
}

resource "google_service_account_iam_member" "planner_wif" {
  service_account_id = google_service_account.planner.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "${local.pool_principal}/*"
}

# プロジェクト単位の権限。
locals {
  project_roles = {
    deployer = [
      "roles/firebasehosting.admin",
      "roles/firebase.viewer",
      "roles/serviceusage.serviceUsageConsumer",
    ]
    preview = [
      "roles/firebasehosting.admin",
      "roles/firebase.viewer",
      "roles/serviceusage.serviceUsageConsumer",
    ]
    # roles/viewer は使わない（プロジェクト内のすべてを読めてしまうため）。plan に要るのは Firebase の読み取りだけ。
    planner = [
      "roles/firebase.viewer",
      "roles/serviceusage.serviceUsageConsumer",
    ]
  }

  sa_emails = {
    deployer = google_service_account.deployer.email
    preview  = google_service_account.preview.email
    planner  = google_service_account.planner.email
  }

  project_role_bindings = merge([
    for sa, roles in local.project_roles : {
      for role in roles : "${sa}/${role}" => { sa = sa, role = role }
    }
  ]...)
}

resource "google_project_iam_member" "ci" {
  for_each = local.project_role_bindings

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${local.sa_emails[each.value.sa]}"
}

# tfstate バケットへの権限はバケット単位で、さらに IAM Condition で app stack の state だけに絞る。
# このバケットには bootstrap stack の state もあるので、それは読み書きさせない。
# 一覧（storage.objects.list）はバケットに対する判定なので、一覧の prefix で絞る（ほかの state の名前も見せない）。
locals {
  bucket_resource    = "projects/_/buckets/${google_storage_bucket.tfstate.name}"
  app_state_dir      = "${var.app_state_prefix}/"
  app_state_cel_expr = "(resource.name == \"${local.bucket_resource}\" && api.getAttribute(\"storage.googleapis.com/objectListPrefix\", \"\").startsWith(\"${local.app_state_dir}\")) || resource.name.startsWith(\"${local.bucket_resource}/objects/${local.app_state_dir}\")"
}

# deployer は app stack の state を読み書きする（apply とロック）。
resource "google_storage_bucket_iam_member" "deployer_state" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.deployer.email}"

  condition {
    title       = "app-state-only"
    description = "app stack の state (${var.app_state_prefix}/) だけ"
    expression  = local.app_state_cel_expr
  }
}

# planner は読むだけ。plan は -lock=false で実行する（ロックファイルを書けないため）。
resource "google_storage_bucket_iam_member" "planner_state" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.planner.email}"

  condition {
    title       = "app-state-only"
    description = "app stack の state (${var.app_state_prefix}/) だけ"
    expression  = local.app_state_cel_expr
  }
}
