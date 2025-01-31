# VPC network
resource "google_compute_network" "vpc_network" {
  project                 = local.project_id
  name                    = local.vpc_network.name
  auto_create_subnetworks = local.vpc_network.auto_create_subnetworks
  mtu                     = local.vpc_network.mtu
}

resource "google_compute_subnetwork" "subnets" {
  name          = local.subnetwork.name
  ip_cidr_range = local.subnetwork.ip_cidr_range
  region        = local.vpc_network.region
  network       = google_compute_network.vpc_network.id

  depends_on = [google_compute_network.vpc_network]
}

# Serverless VPC Access Connector to route traffic into the VPC network
resource "google_vpc_access_connector" "connector" {
  name          = local.vpc_access_connector.name
  region        = local.vpc_network.region
  ip_cidr_range = local.vpc_access_connector.ip_cidr_range
  network       = google_compute_network.vpc_network.name
  min_instances = 2
  max_instances = 10

  depends_on = [google_compute_network.vpc_network]
}

# Bucket for Cloud Function source code
resource "google_storage_bucket" "cf_bucket" {
  name          = "${local.project_id}-${local.cf_bucket.name}"
  location      = local.cf_bucket.location
  storage_class = local.cf_bucket.storage_class
  force_destroy = true
}

# Bucket objet for source code
resource "google_storage_bucket_object" "cf_source" {
  name   = "cf-code-${md5(filemd5("cf-code/cf-source.zip"))}.zip"
  bucket = google_storage_bucket.cf_bucket.name
  source = "cf-code/cf-source.zip"
}

# Bucket for Cloud Function source code (BUCKET TRIGGERED CLOUD FUNCTION)
resource "google_storage_bucket" "cf_bucket_triggered" {
  name          = "${local.project_id}-gcf-bucket-triggered"
  location      = local.cf_bucket.location
  storage_class = local.cf_bucket.storage_class
  force_destroy = true
}

# Bucket objet for source code (BUCKET TRIGGERED CLOUD FUNCTION)
resource "google_storage_bucket_object" "cf_source_triggered" {
  name   = "cf-code-${md5(filemd5("cf-code-bucket-triggered/cf-source.zip"))}.zip"
  bucket = google_storage_bucket.cf_bucket_triggered.name
  source = "cf-code-bucket-triggered/cf-source.zip"

  depends_on = [google_storage_bucket.cf_bucket_triggered]
}

# 1st gen Cloud Function (not used)
# resource "google_cloudfunctions_function" "google_cloud_function" {
#   name                = local.cloud_function.name
#   description         = local.cloud_function.description
#   runtime             = local.cloud_function.runtime
#   available_memory_mb = local.cloud_function.memory_mb

#   source_archive_bucket         = google_storage_bucket.cf_bucket.name
#   source_archive_object         = local.cloud_function.source_object
#   environment_variables         = local.cloud_function.environment_variables
#   vpc_connector                 = google_vpc_access_connector.connector.name
#   vpc_connector_egress_settings = local.cloud_function.vpc_connector_egress_settings

#   trigger_http = local.cloud_function.trigger_http
#   entry_point  = local.cloud_function.entry_point

#   depends_on = [google_vpc_access_connector.connector, google_storage_bucket.cf_bucket]
# }

# Resource for GCS trigger for Cloud Function
#------------------------------------------------------------------------------------------------------
data "google_storage_project_service_account" "gcs_account" {
}

resource "google_project_iam_member" "gcs-pubsub-publishing" {
  project = local.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
}
#------------------------------------------------------------------------------------------------------

# 2gen Cloud Function
resource "google_cloudfunctions2_function" "google_cloud_function_2gen" {
  name        = local.cloud_function.name
  description = local.cloud_function.description
  location    = local.cloud_function.location_cf

  build_config {
    runtime     = local.cloud_function.runtime
    entry_point = local.cloud_function.entry_point

    source {
      storage_source {
        bucket = google_storage_bucket.cf_bucket.name
        object = google_storage_bucket_object.cf_source.name
      }
    }
  }

  service_config {
    available_memory = local.cloud_function.memory_mb       # Memoria disponibile per la funzione
    timeout_seconds  = local.cloud_function.timeout_seconds # Timeout per l'esecuzione della funzione (in secondi)
    available_cpu    = local.cloud_function.available_cpu   # CPU disponibili per la funzione

    environment_variables = local.cloud_function.environment_variables

    vpc_connector                 = google_vpc_access_connector.connector.name
    vpc_connector_egress_settings = local.cloud_function.vpc_connector_egress_settings

    max_instance_count = local.cloud_function.max_instance_count

    secret_environment_variables {
      key        = "sftp_password"
      project_id = local.project_id
      secret     = google_secret_manager_secret.sftp_password.secret_id
      version    = "latest"
    }

    service_account_email = google_service_account.sa.email

  }

  depends_on = [google_vpc_access_connector.connector, google_storage_bucket.cf_bucket, google_storage_bucket_object.cf_source]
}

# 2gen Cloud Function (BUCKET TRIGGERED VERSION)
# resource "google_cloudfunctions2_function" "google_cloud_function_2gen_triggered" {
#   name        = "${local.cloud_function.name}-triggered"
#   description = local.cloud_function.description
#   location    = local.cloud_function.location_cf

#   build_config {
#     runtime     = local.cloud_function.runtime
#     entry_point = local.cloud_function.entry_point

#     source {
#       storage_source {
#         bucket = google_storage_bucket.cf_bucket_triggered.name
#         object = google_storage_bucket_object.cf_source_triggered.name
#       }
#     }
#   }

#   service_config {
#     available_memory = local.cloud_function.memory_mb
#     timeout_seconds  = local.cloud_function.timeout_seconds_triggered_cf
#     available_cpu    = local.cloud_function.available_cpu

#     environment_variables = local.cloud_function.environment_variables

#     vpc_connector                 = google_vpc_access_connector.connector.name
#     vpc_connector_egress_settings = local.cloud_function.vpc_connector_egress_settings

#     max_instance_count = local.cloud_function.max_instance_count

#     secret_environment_variables {
#       key        = "sftp_password"
#       project_id = local.project_id
#       secret     = google_secret_manager_secret.sftp_password.secret_id
#       version    = "latest"
#     }

#     service_account_email = google_service_account.sa.email

#   }

#   event_trigger {
#     trigger_region        = "eu"
#     event_type            = "google.cloud.storage.object.v1.finalized"
#     retry_policy          = "RETRY_POLICY_RETRY"
#     service_account_email = google_service_account.sa.email
#     event_filters {
#       attribute = "bucket"
#       value     = google_storage_bucket.landing_bucket.name
#     }
#   }

#   depends_on = [google_vpc_access_connector.connector, google_storage_bucket.cf_bucket_triggered, google_storage_bucket_object.cf_source_triggered, google_project_iam_member.gcs-pubsub-publishing]
# }

# Static IP
resource "google_compute_address" "nat_ip" {
  name = local.static_ip.name
}

# Router
resource "google_compute_router" "router" {
  name    = local.router.name
  region  = local.vpc_network.region
  network = google_compute_network.vpc_network.name

  depends_on = [google_compute_network.vpc_network]
}

# Cloud NAT
resource "google_compute_router_nat" "nat" {
  name   = "${local.router.name}-nat"
  router = google_compute_router.router.name
  region = google_compute_router.router.region

  nat_ip_allocate_option             = local.router.nat_ip_allocate_option
  nat_ips                            = [google_compute_address.nat_ip.self_link]
  source_subnetwork_ip_ranges_to_nat = local.router.source_subnetwork_ip_ranges_to_nat

  log_config {
    enable = local.router.log_config_enable
    filter = local.router.log_filter
  }

  depends_on = [google_compute_router.router]
}

# # Cloud Scheduler job to trigger the Cloud Function for each table listed in the yaml
resource "google_cloud_scheduler_job" "daily_trigger_job" {
  for_each = { for job in local.config.sftp_connector.cloud_scheduler_jobs_prd : job.table => job }

  name             = "${replace(replace(each.value.table, ".txt", ""), ".csv", "")}-scheduler-job"
  description      = "Job to trigger Cloud Function for SFTP to GCS import for table ${replace(replace(each.value.table, ".txt", ""), ".csv", "")}"
  schedule         = each.value.schedule
  region           = "europe-west1"
  time_zone        = "Europe/Rome"
  attempt_deadline = "1800s"

  http_target {
    uri         = "https://${local.cloud_function.location_cf}-${local.project_id}.cloudfunctions.net/import-sftp-tables-to-gcs"
    http_method = "POST"
    body        = base64encode(jsonencode({ "file_name" = each.value.table }))
    headers = {
      Content-Type = "application/json"
    }

    oidc_token {
      service_account_email = google_service_account.sa.email
    }
  }

  depends_on = [google_cloudfunctions2_function.google_cloud_function_2gen]
}

# -------------------------------------------------------------------------------------
# CF which triggers only Dataform
# -------------------------------------------------------------------------------------

# Bucket for Cloud Function source code (CF TRIGGERS ONLY DATAFORM)
resource "google_storage_bucket" "cf_bucket_only_dataform" {
  name          = "${local.project_id}-gcf-bucket-only-dataform"
  location      = local.cf_bucket.location
  storage_class = local.cf_bucket.storage_class
  force_destroy = true
}

# Bucket objet for source code (CF TRIGGERS ONLY DATAFORM)
resource "google_storage_bucket_object" "cf_source_only_dataform" {
  name   = "cf-code-${md5(filemd5("cf-code-only-dataform/cf-source.zip"))}.zip"
  bucket = google_storage_bucket.cf_bucket_only_dataform.name
  source = "cf-code-only-dataform/cf-source.zip"

  depends_on = [google_storage_bucket.cf_bucket_only_dataform]
}

# 2gen Cloud Function
resource "google_cloudfunctions2_function" "google_cloud_function_only_dataform" {
  name        = "dataform-trigger"
  description = "CF which triggers only Dataform"
  location    = local.cloud_function.location_cf

  build_config {
    runtime     = local.cloud_function.runtime
    entry_point = local.cloud_function.entry_point

    source {
      storage_source {
        bucket = google_storage_bucket.cf_bucket_only_dataform.name
        object = google_storage_bucket_object.cf_source_only_dataform.name
      }
    }
  }

  service_config {
    available_memory = local.cloud_function.memory_mb
    timeout_seconds  = local.cloud_function.timeout_seconds
    available_cpu    = local.cloud_function.available_cpu

    environment_variables = local.cloud_function.environment_variables

    vpc_connector                 = google_vpc_access_connector.connector.name
    vpc_connector_egress_settings = local.cloud_function.vpc_connector_egress_settings

    max_instance_count = local.cloud_function.max_instance_count

    secret_environment_variables {
      key        = "sftp_password"
      project_id = local.project_id
      secret     = google_secret_manager_secret.sftp_password.secret_id
      version    = "latest"
    }

    service_account_email = google_service_account.sa.email

  }

  depends_on = [google_vpc_access_connector.connector, google_storage_bucket.cf_bucket_only_dataform, google_storage_bucket_object.cf_source_only_dataform]
}

# Cloud Scheduler job to trigger the Cloud Function for each table listed in the yaml
resource "google_cloud_scheduler_job" "daily_trigger_job_only_dataform" {
  for_each = { for job in local.config.sftp_connector.cloud_scheduler_jobs_only_dataform_prd : job.table => job }

  name             = "${replace(replace(each.value.table, ".txt", ""), ".csv", "")}-scheduler-job-only-dataform"
  description      = "Job to trigger Dataform for table ${replace(replace(each.value.table, ".txt", ""), ".csv", "")}"
  schedule         = each.value.schedule
  region           = "europe-west1"
  time_zone        = "Europe/Rome"
  attempt_deadline = "1800s"

  http_target {
    uri         = "https://${local.cloud_function.location_cf}-${local.project_id}.cloudfunctions.net/dataform-trigger"
    http_method = "POST"
    body        = base64encode(jsonencode({ "file_name" = each.value.table }))
    headers = {
      Content-Type = "application/json"
    }

    oidc_token {
      service_account_email = google_service_account.sa.email
    }
  }

  depends_on = [google_cloudfunctions2_function.google_cloud_function_only_dataform]
}
