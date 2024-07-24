resource "google_project_service" "api" {
  for_each = toset(local.enabled_apis)
  project  = local.project_id
  service  = each.value
}
