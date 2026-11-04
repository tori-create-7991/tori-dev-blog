# GCP プロジェクトで Firebase を有効にする。
# CI の deployer には Firebase を有効化する権限を渡さないので、app stack ではなくこの stack が持つ。
# プロジェクトを名刺サイトと共有しているが、Firebase の有効化はこのリポジトリだけが持つ。
resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id

  depends_on = [google_project_service.this]
}
