output "wif_provider" {
  description = "WIF Provider の完全名（GitHub Variables の WIF_PROVIDER に登録済み）"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "service_accounts" {
  description = "CI 用 SA"
  value       = local.sa_emails
}

output "prod_site_url" {
  description = "本番サイトの URL"
  value       = local.prod_site_url
}
