# CI 用の SA。役割ごとに分け、それぞれ必要な権限だけを持つ。
# 命名ルール: gha-<slug>-<役割>。
#
#   deployer  main ブランチのみ。app stack の apply と本番への配信
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
resource "google_service_account_iam_member" "deployer_wif" {
  service_account_id = google_service_account.deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "${local.pool_principal}/attribute.ref/refs/heads/main"
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
    planner = [
      "roles/viewer",
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
# このバケットには他リポジトリや bootstrap stack の state もあるので、それらは読み書きさせない。
# バケット自体への条件（resource.name == バケット）は、Terraform の GCS backend が
# オブジェクト一覧を取るために要る（一覧で見えるのは名前だけで、中身は読めない）。
locals {
  bucket_resource    = "projects/_/buckets/${google_storage_bucket.tfstate.name}"
  app_state_objects  = "${local.bucket_resource}/objects/${var.app_state_prefix}/default."
  app_state_cel_expr = "resource.name == \"${local.bucket_resource}\" || resource.name.startsWith(\"${local.app_state_objects}\")"
}

# deployer は app stack の state を読み書きする（apply とロック）。
resource "google_storage_bucket_iam_member" "deployer_state" {
  bucket = google_storage_bucket.tfstate.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.deployer.email}"

  condition {
    title       = "app-state-only"
    description = "app stack の state (${var.app_state_prefix}/default.*) だけ"
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
    description = "app stack の state (${var.app_state_prefix}/default.*) だけ"
    expression  = local.app_state_cel_expr
  }
}
