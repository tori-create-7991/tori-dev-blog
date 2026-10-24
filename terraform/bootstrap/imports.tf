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
