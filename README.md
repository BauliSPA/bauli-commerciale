# bauli-commerciale

Repository with all the infrastructure necessary for the connection between Board and Google BigQuery.
Everything is handled in a centralized way via Terraform.


## Terraform CD/CI

Terraform CD/CI is configured in `terraform.yml` inside the `.github/` folder.

### Workflow Overview

This setup automates Terraform operations (init, plan, and apply) for both `dev` and `prd` environments. The workflows are triggered as follows:
- **Pull Requests**:
  - Runs `terraform init` and `terraform plan` for both `dev` and `prd` environments.
  - The `terraform apply` for `dev` requires **manual approval** in the `development` environment.
- **Merge to Main**:
  - Runs `terraform init`, `terraform plan`, and `terraform apply` for the `prd` environment, with **manual approval** in the `production` environment.

### Secrets Required
- **Development Environment**:
  - `GOOGLE_CREDENTIALS_DEV`
  - `GOOGLE_PROJECT_DEV`
- **Production Environment**:
  - `GOOGLE_CREDENTIALS_PRD`
  - `GOOGLE_PROJECT_PRD`

### Changing the User for Approvals in GitHub Environments for `development` and `production` 
GitHub Environments allows to enforce manual approvals for specific workflows, such as the `Terraform Apply` jobs in the CI/CD pipeline. Follow these steps to modify the user(s) responsible for approvals in `development` or `production` environments:

1. **Access the Environment Settings**:
   - Go to the GitHub repository `bauli-commerciale`.
   - Navigate to `Settings` → `Environments`.
   - Click on the environment you want to modify (e.g., `development` or `production`).

2. **Modify the Required Approvers**:
   - Under the **Environment protection rules**, locate the **Required reviewers** section.
   - Add or remove users, teams, or organization members who should approve jobs in this environment.
   - Ensure that the users or teams you select have the appropriate permissions in the repository (typically `write` or `maintain` access).

3. **Save Changes**:
   - After updating the required reviewers, click **Save protection rules** to apply the changes.

4. **Verify the Workflow**:
   - Trigger a workflow that requires manual approval (e.g., push to `main` or a pull request targeting `main`).
   - Check if the new approver(s) receive the approval request.

### Notes:
- You can add multiple users or teams to the approval process, ensuring flexibility for different workflows.
- If you remove all required reviewers, the manual approval step will no longer be enforced in that environment.
- Make sure the `environment` field in your GitHub Actions workflow YAML file matches the environment name configured in the repository settings.

By following these steps, you can easily update the user(s) responsible for approvals in your GitHub Actions workflows.


## Directory Structure

```bash
.
├── README.md
├── .github
|   └── terraform.yml
├── .gitignore
└── terraform
    ├── _bauli_commercial.yml
    ├── dev
    │   ├── apis.tf
    │   ├── cf-code
    │   │   ├── cf-source.zip
    │   │   ├── main.py
    │   │   └── requirements.txt
    │   ├── cf-code-bucket-triggered
    │   │   ├── cf-source.zip
    │   │   ├── main.py
    │   │   └── requirements.txt
    │   ├── cf-code-only-dataform
    │   │   ├── cf-source.zip
    │   │   ├── main.py
    │   │   └── requirements.txt
    │   ├── dataform
    │   │   ├── bq_dataform.tf
    │   │   ├── dataform.tf
    │   │   ├── iam_and_sa_dataform.tf
    │   │   ├── secrets_dataform.tf
    │   │   └── variables.tf
    │   ├── foundation.tf
    │   ├── iam_and_sa.tf
    │   ├── main.tf
    │   ├── secrets.tf
    │   ├── sftp_connector.tf
    │   ├── state_bucket.tf
    │   └── storage.tf
    ├── prd
    │   ├── apis.tf
    │   ├── cf-code
    │   │   ├── cf-source.zip
    │   │   ├── main.py
    │   │   └── requirements.txt
    │   ├── cf-code-only-dataform
    │   │   ├── cf-source.zip
    │   │   ├── main.py
    │   │   └── requirements.txt
    │   ├── dataform
    │   │   ├── bq_dataform.tf
    │   │   ├── dataform.tf
    │   │   ├── iam_and_sa_dataform.tf
    │   │   ├── secrets_dataform.tf
    │   │   └── variables.tf
    │   ├── foundation.tf
    │   ├── iam_and_sa.tf
    │   ├── main.tf
    │   ├── secrets.tf
    │   ├── sftp_connector.tf
    │   ├── state_bucket.tf
    │   └── storage.tf
    └── tables_configuration
        └── config.json
