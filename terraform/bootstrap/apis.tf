# この stack と app stack・CI が使う API。無効化はしない。
# プロジェクトを名刺サイト（01_self-digital-business-card）と共有しているので、
# API と Firebase の有効化はこのリポジトリだけが持つ（名刺側は持たない）。
locals {
  services = toset([
    "cloudresourcemanager.googleapis.com",
    "firebase.googleapis.com",
    "firebasehosting.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
  ])
}

resource "google_project_service" "this" {
  for_each = local.services

  service            = each.value
  disable_on_destroy = false
}
