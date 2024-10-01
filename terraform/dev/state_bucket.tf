# Create state bucket for Terraform
resource "google_storage_bucket" "terraform_state" {
  name          = "${local.project_id}-${local.terraform_state_bucket_name}"
  location      = local.terraform_state_bucket_location
  storage_class = local.terraform_state_bucket_class
  force_destroy = true
}
