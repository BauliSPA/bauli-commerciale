# TODO: RICEVERE DETTAGLI SULLA RISORSA ED AGGIUNGERLA
# resource "google_dataform_repository" "dataform_repository" {
#   provider     = google-beta
#   name         = var.dataform_repository_name
#   display_name = var.dataform_repository_display_name
#   region       = var.dataform_repository_region
#   project      = var.project_id
# }

# resource "google_dataform_repository_release_config" "release" {
#   provider      = google-beta
#   project       = var.project_id
#   region        = var.dataform_repository_region
#   repository    = google_dataform_repository.dataform_repository.name
#   name          = var.dataform_release_config_name
#   git_commitish = var.dataform_release_config_git_commitish
#   cron_schedule = var.dataform_release_config_cron_schedule
#   time_zone     = var.dataform_release_config_time_zone

#   code_compilation_config {
#     default_database = var.dataform_release_config_code_compilation_config.default_database
#     default_schema   = var.dataform_release_config_code_compilation_config.default_schema
#     default_location = var.dataform_release_config_code_compilation_config.default_location
#     assertion_schema = var.dataform_release_config_code_compilation_config.assertion_schema
#     vars             = var.dataform_release_config_code_compilation_config.vars
#   }
# }

# resource "google_dataform_repository_workflow_config" "workflow_config" {
#   provider   = google-beta
#   project    = var.project_id
#   repository = google_dataform_repository.dataform_repository.name
#   name       = var.dataform_workflow_config_name
#   location   = var.dataform_repository_region
#   included_targets {
#     database   = var.dataform_workflow_config_included_targets.database
#     dataset_id = var.dataform_workflow_config_included_targets.dataset_id
#   }
#   trigger {
#     cron_expression = var.dataform_workflow_config_cron_expression
#   }
# }
