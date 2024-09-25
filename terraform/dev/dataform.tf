resource "google_dataform_repository" "dataform_repository" {
  provider     = google-beta
  name         = local.dataform_repository_name
  display_name = local.dataform_display_name
  region       = local.dataform_region 
  project      = local.project_id
}
