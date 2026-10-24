# Cloud Run API有効化
resource "google_project_service" "run" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

# Artifact Registry API有効化
resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Artifact Registryリポジトリ
resource "google_artifact_registry_repository" "app" {
  location      = var.region
  repository_id = "${var.cloudrun_service_name}-images"
  format        = "DOCKER"
  description   = "Docker images for ${var.cloudrun_service_name}"

  depends_on = [google_project_service.artifactregistry]
}

output "artifact_registry_url" {
  description = "Artifact RegistryのURL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.app.repository_id}"
}
