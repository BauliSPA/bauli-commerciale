# TODO: AGGIUNGERE RISORSE PER SEGRETO CHIAVE PER ACCEDERE AL REPOSITORY

# resource "google_secret_manager_secret" "gitlab_token" {
#   project   = var.project_id
#   secret_id = "gitlab_token"

#   replication {
#     user_managed {
#       replicas {
#         location = 
#       }
#     }
#   }
# }


# resource "google_secret_manager_secret_version" "gitlab_token" {
#   secret = google_secret_manager_secret.gitlab_token.id

#   secret_data = var.dataform_demo_gitlab_token
# }