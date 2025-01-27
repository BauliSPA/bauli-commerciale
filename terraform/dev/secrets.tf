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
#   --project "bli-bi-commerciale-test-001" \
#   --location "europe-west1" \
#   --keyring "product_keyring" \
#   --key "product_key" \
#   --plaintext-file tmp \
#   --ciphertext-file - | base64 -w 0

# 4) Create the data resource for the password decrypted
# Decrypted secrets
data "google_kms_secret" "secret_decrypted" {
  crypto_key = "projects/${local.project_id}/locations/${local.secrets.location}/keyRings/${local.secrets.keyring_name}/cryptoKeys/${local.secrets.key_name}"
  ciphertext = "CiQAbDBkX6YeCnxrU/zZQWyIsPj09I9YOgu3PimdT8tudilCaM8SOgB/EfjIiZCNMg0U0FzWh+5SZkSfHeSkqxjJ0G/A7WF0CVVv0x1gSPUg/CLGjp93NqBV0f9CbQlJpos=" # Insert here the output of the bash gcloud above
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
data "google_kms_secret" "ssh_private_key_secret_dev_decrypted" {
  crypto_key = "projects/${local.project_id}/locations/${local.secrets.location}/keyRings/${local.secrets.keyring_name}/cryptoKeys/${local.secrets.key_name}"
  ciphertext = "CiQAbDBkX1k8rWfE9TGsr3HP3X/dJp/AHAFQmGqzWYbBW5fU5G0SzAMAfxH4yN0Ci2OsT8c5lcEhEJ7dFzbR77LXJs+NiowhaD9bmYAGGGX6ATML2ag7a6mlJ/A/0xLiLga1CTqHO/HF2eTTqKeQDjpycVTUo5cNDYKFNf0t9DUNBQ1e72eQoMUbVLTikmmzwcy9gU8k/gGLdK975IwKmJu/4yPJtdvidAqXTi1h+uUgwjlEaFtK3hjwJK1gHE1dd6i8p8DpusSDwi9QzsY4HBWa4+IAL3woJomYaB/OSFDn0V2gVkz788pmy6fNIw/fuIGQYCIuqsZyRvl6qs3QdkhtJgaMSV44hPxzEw8pX4MvhmBCnrltX2eRT7GWmtCyG8NJ37Jx1uLWvMdQJF62ZkjHj/l6+Pkv9cwqrwU8rMDdYhJwLykjk919lmLBMYtnYvylW/bRaCNT+EA8iKWa0fiDEPI0Y5LRTNy+l1ouagP59dW634QT6geUKG8m3UzQNCVPsebrDr1asMj1RpLo7bFaThEvjcZdybC0HVTqQUKEU0bhfYfepmapb4ARjCam9rDpiRAXe+2rKIsF6UkosLEW7XdVm+5hSeEhtwP7UkPmxVsfwZpn4yWCdiLyHbqL3837ewhkFj9G66+LiW9W+3Y2Wopt"
}

resource "google_secret_manager_secret" "ssh_private_key_dev_secret" {
  secret_id = "ssh-private-key-dev-secret"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "ssh_private_key_secret_dev_version" {
  secret      = google_secret_manager_secret.ssh_private_key_dev_secret.id
  secret_data = data.google_kms_secret.ssh_private_key_secret_dev_decrypted.plaintext

  depends_on = [google_secret_manager_secret.ssh_private_key_dev_secret]
}
