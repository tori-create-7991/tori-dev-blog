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

# API の有効化は bootstrap stack へ移した（bootstrap が import する）。
removed {
  from = google_project_service.firebase
  lifecycle {
    destroy = false
  }
}

removed {
  from = google_project_service.firebasehosting
  lifecycle {
    destroy = false
  }
}

removed {
  from = google_project_service.iam
  lifecycle {
    destroy = false
  }
}

removed {
  from = google_project_service.iamcredentials
  lifecycle {
    destroy = false
  }
}

removed {
  from = google_project_service.cloudresourcemanager
  lifecycle {
    destroy = false
  }
}

removed {
  from = google_project_service.sts
  lifecycle {
    destroy = false
  }
}

# 旧 CI 用 SA・旧 WIF Provider（共有 Pool github-pool 内）・SA の WIF binding。
# 新しい専用 Pool と SA は bootstrap stack が作る。
# これらは新構成で CI が通ってから、移行手順 6 で gcloud により削除する。
removed {
  from = google_service_account.github_actions
  lifecycle {
    destroy = false
  }
}

removed {
  from = google_iam_workload_identity_pool_provider.github
  lifecycle {
    destroy = false
  }
}

removed {
  from = google_service_account_iam_member.wif_sa_binding
  lifecycle {
    destroy = false
  }
}

# 次の 2 つは removed を書かない。定義を消したので apply で destroy され、
# 旧 CI 用 SA が持っていた強い権限（プロジェクトの IAM・WIF・SA を管理できるロールなど 8 件）と
# tfstate バケットへの storage.admin が剥奪される。
#   google_project_iam_member.github_actions
#   google_storage_bucket_iam_member.github_actions_tfstate
