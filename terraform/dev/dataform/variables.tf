# Variables for module "Dataform"

variable "project_id" {
  description = "The project ID for the Google Cloud project."
  type        = string
}

variable "bigquery" {
  description = "List of BigQuery datasets to create."
  type = list(object({
    dataset_name    = string
    dataset_location = string
  }))
}

variable "dataform_repository_name" {
  description = "The name of the Dataform repository."
  type        = string
}

variable "dataform_repository_display_name" {
  description = "The display name of the Dataform repository."
  type        = string
}

variable "dataform_repository_region" {
  description = "The region where the Dataform repository is located."
  type        = string
}

variable "dataform_release_config_name" {
  description = "The name of the Dataform release configuration."
  type        = string
}

variable "dataform_release_config_git_commitish" {
  description = "The Git branch or commitish for the Dataform release configuration."
  type        = string
}

variable "dataform_release_config_cron_schedule" {
  description = "The cron schedule for the Dataform release configuration."
  type        = string
}

variable "dataform_release_config_time_zone" {
  description = "The time zone for the cron schedule of the Dataform release configuration."
  type        = string
}

variable "dataform_release_config_code_compilation_config" {
  description = "Configuration for code compilation in Dataform."
  type = object({
    default_database   = string   # The default database for code compilation.
    default_schema     = string   # The default schema for code compilation.
    default_location   = string   # The location for code compilation.
    assertion_schema   = string   # The schema for assertions.
    vars               = map(string) # A map of variables used in code compilation.
  })
}

variable "dataform_workflow_config_name" {
  description = "The name of the Dataform workflow configuration."
  type        = string
}

variable "dataform_workflow_config_cron_expression" {
  description = "The cron expression for the Dataform workflow configuration."
  type        = string
}

variable "dataform_workflow_config_included_targets" {
  description = "A map of targets included in the Dataform workflow configuration."
  type        = map(string)
}
