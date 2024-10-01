locals {
  config = yamldecode(file("../_bauli_commercial.yml"))

  # Primary parameters
  project_id = local.config.project_id_dev
  location   = local.config.location

  # Foundation IAM
  admins_roles      = local.config.foundation_iam.dev.data_admins
  developers_roles  = local.config.foundation_iam.dev.data_developers
  maintainers_roles = local.config.foundation_iam.dev.data_maintainers

  # Landing bucket
  landing_bucket_name          = local.config.landing_bucket.name
  landing_bucket_location      = local.config.landing_bucket.location
  landing_bucket_storage_class = local.config.landing_bucket.storage_class

  # TODO: implementare una lista di sa e i loro permessi?
  sa_private_key_type   = local.config.service_account.private_key_type
  sa_key_algorithm      = local.config.service_account.key_algorithm
  service_account_roles = local.config.service_account.roles

  # APIs
  enabled_apis = local.config.enabled_apis

  # Terraform state bucket
  terraform_state_bucket_name     = local.config.state_bucket_terraform.name
  terraform_state_bucket_location = local.config.state_bucket_terraform.location
  terraform_state_bucket_class    = local.config.state_bucket_terraform.storage_class

}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }

  backend "gcs" {
    bucket = "bli-bi-commerciale-test-001-terraform-state-bucket" # This cannot be dynamically computed
    prefix = "terraform/state"
  }
}

provider "google" {
  project = local.project_id
  region  = local.location
}

# Modules
module "dataform" {
  source     = "./dataform"
  project_id = local.project_id

  # BigQuery datasets for Dataform
  bigquery = local.config.bigquery

  # Dataform configurations
  dataform_repository_name         = local.config.dataform.repository.name
  dataform_repository_display_name = local.config.dataform.repository.display_name
  dataform_repository_region       = local.config.dataform.repository.region

  dataform_release_config_name          = local.config.dataform.release_config.name
  dataform_release_config_git_commitish = local.config.dataform.release_config.git_commitish
  dataform_release_config_cron_schedule = local.config.dataform.release_config.cron_schedule
  dataform_release_config_time_zone     = local.config.dataform.release_config.time_zone

  dataform_release_config_code_compilation_config = {
    default_database = local.config.dataform.release_config.code_compilation_config.default_database
    default_schema   = local.config.dataform.release_config.code_compilation_config.default_schema
    default_location = local.config.dataform.release_config.code_compilation_config.default_location
    assertion_schema = local.config.dataform.release_config.code_compilation_config.assertion_schema
    vars             = local.config.dataform.release_config.code_compilation_config.vars
  }

  dataform_workflow_config_name             = local.config.dataform.workflow_config.name
  dataform_workflow_config_cron_expression  = local.config.dataform.workflow_config.cron_expression
  dataform_workflow_config_included_targets = local.config.dataform.workflow_config.included_targets
}
