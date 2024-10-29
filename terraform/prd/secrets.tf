# Create the KeyRing for KMS
resource "google_kms_key_ring" "product_keyring" {
  name     = local.secrets.keyring_name
  location = local.secrets.location
}

# Create a KMS key to encrypt the secret
resource "google_kms_crypto_key" "product_key" {
  name       = local.secrets.key_name
  key_ring   = google_kms_key_ring.product_keyring.id
  depends_on = [google_kms_key_ring.product_keyring]
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# After the creation of keyring and key, uncomment the following lines  #
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# 1) create a local temporary file, such as tmp, and paste the secret into it.

# 2) secret: <SEGRETO>

# 3) Command to encrypt the secret using KMS:
#
# gcloud kms encrypt \
#   --project "bli-bi-commerciale-prod-001" \
#   --location "europe-west1" \
#   --keyring "product_keyring" \
#   --key "product_key" \
#   --plaintext-file tmp \
#   --ciphertext-file - | base64 -w 0

# 4) Create the data resource for the password decrypted
# Decrypted secrets
data "google_kms_secret" "secret_decrypted" {
  crypto_key = "projects/${local.project_id}/locations/${local.secrets.location}/keyRings/${local.secrets.keyring_name}/cryptoKeys/${local.secrets.key_name}"
  ciphertext = "CiQAa+yO9DRiMM8AA7K/2OTjDr9hQJ+NqbppsPoC1N6EzaOjLRsSOgD05WCVU7Ogpi1D2d9Sbra1qmmLuHnzeyyCcBbcjzILqKVgOeWlJaupoqQFgvJYQG6uvmO6mrwF2bA=" # Insert here the output of the bash gcloud above
}


# 5) Create the secret in Secret Manager
resource "google_secret_manager_secret" "sftp_password" {
  secret_id = local.secrets.secret_password
  replication {
    auto {}
  }

  depends_on = [google_kms_crypto_key.product_key]
}

# 6) Create the version of the secret with the encrypted content
resource "google_secret_manager_secret_version" "sftp_password_version" {
  secret      = google_secret_manager_secret.sftp_password.id
  secret_data = data.google_kms_secret.secret_decrypted.plaintext

  depends_on = [google_secret_manager_secret.sftp_password]
}
