# bauli-commerciale

Repository with all the infrastructure necessary for the connection between SAP Datasphere and Google BigQuery via Terraform.

## Directory Structure

.
├── README.md
└── terraform
    ├── _bauli_commercial.yml
    ├── dev
    │   ├── apis.tf
    │   ├── bigquery.tf
    │   ├── iam_and_sa.tf
    │   ├── main.tf
    │   ├── state_bucket.tf
    │   └── storage.tf
    ├── modules
    ├── prd
    │   ├── apis.tf
    │   ├── bigquery.tf
    │   ├── iam_and_sa.tf
    │   ├── main.tf
    │   ├── state_bucket.tf
    │   └── storage.tf
    └── sa_keys
        ├── sa_key_dev.json
        └── sa_key_prd.json
