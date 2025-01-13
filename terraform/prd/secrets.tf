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

# SSH private key secret for GitHub-Dataform link
data "google_kms_secret" "ssh_private_key_secret_decrypted" {
  crypto_key = "projects/${local.project_id}/locations/${local.secrets.location}/keyRings/${local.secrets.keyring_name}/cryptoKeys/${local.secrets.key_name}"
  ciphertext = "CiQAa+yO9IljieCDyyFIhhnMXkSf0fkjqop8DoV0Kksw4cUcG4IShgMA9OVglRoOSthF5Ewnd8Ir6tYvqEajOL3lgh3Zamdsr6WL9KWp+L1B9yYwIV8NmHOnV465qj46biZmKSRpeMQPI75gQKGFB23lh3ydYZZAx7dzw+Na3/VsqYuo5xO6hC9dDz/5AAN/ezZ/+KP/w0dqhsuMdUmcMrZkGaEsYHaQxfYbscQks7kLVdf9fLWoBsqF9N+Hko8n4LDrsHnol3iUa8wx3JmKTSVP8nMK/Jd313b6+qvQwP5DpwsFyHdoxKDYh7ZPREovMkLYbORznVTEcCEAhfi+k8p15qDqNT494nGJrXsu359NVnexd3MKScBeLlDUFrGOq3869s+JokZp5UK+N0xeG59oG+Wh1WLl1v6bstrS809RTm0OVwvnwNjYgZpUiJfoGwJGCJYdUxV7hXL77Erb/fC+YBPMGtNeZeNWXegpLoAnseBcV1hIK49nFg/TFARm42Qt3QAphQbEGPJgw2x6m1uoaMMEhJEJKWpyRqb9GKncvE631ZHUXLODuFf3t7A="
}

resource "google_secret_manager_secret" "ssh_private_key_secret" {
  secret_id = "ssh-private-key-secret"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ssh_private_key_secret_version" {
  secret      = google_secret_manager_secret.ssh_private_key_secret.id
  secret_data = data.google_kms_secret.ssh_private_key_secret_decrypted.plaintext

  depends_on = [google_secret_manager_secret.ssh_private_key_secret]
}