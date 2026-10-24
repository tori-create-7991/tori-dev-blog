# tfstate を置くバケット。最初の 1 回だけ gcloud で作り（Terraform の state を置く場所が
# 先に要るため）、この stack に import して以降は Terraform で管理する。
resource "google_storage_bucket" "tfstate" {
  name                        = var.tf_state_bucket
  location                    = var.tf_state_bucket_location
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # state の世代を残し、誤った apply から戻せるようにする。
  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [google_project_service.this]
}
