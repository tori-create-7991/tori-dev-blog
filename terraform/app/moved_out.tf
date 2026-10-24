# app stack から外したリソース。
#
# removed { lifecycle { destroy = false } } は「state から外すだけで、実リソースは消さない」。
# API の有効化は bootstrap stack が import して引き継ぐ。
# ここに書かれていない旧リソースは、定義の削除によって destroy される（意図した削除）。

# Cloud Run 構成の名残。API は無効化しない（他のサービスが使っている可能性があるため）。
removed {
  from = google_project_service.run
  lifecycle {
    destroy = false
  }
}

removed {
  from = google_project_service.artifactregistry
  lifecycle {
    destroy = false
  }
}
