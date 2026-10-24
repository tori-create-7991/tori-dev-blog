# Firebase プロジェクトの初期化。
# 必要な API の有効化は bootstrap stack が管理する。
resource "google_firebase_project" "default" {
  provider = google-beta
  project  = var.project_id
}
