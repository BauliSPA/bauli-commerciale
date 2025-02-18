import json
import os
import requests
import time
from google.cloud import storage, bigquery, dataform_v1beta1, secretmanager

# Function to get secret from Secret Manager
def get_secret(secret_name):
    """Retrieve the secret from Secret Manager."""
    client = secretmanager.SecretManagerServiceClient()
    project_id = os.getenv("GCP_PROJECT_ID", "bli-bi-commerciale-test-001").replace("env", "test")
    secret_path = f"projects/{project_id}/secrets/{secret_name}/versions/latest"
    
    response = client.access_secret_version(name=secret_path)
    return response.payload.data.decode("UTF-8")

# Load schema from JSON configuration in GCS
def load_schema_from_config(bucket_name, config_path, table_name):
    """Load table schema from JSON configuration in GCS."""
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(config_path)

    config_data = json.loads(blob.download_as_text())
    for table in config_data.get("tables", []):
        if table["table_name"] == table_name:
            print(f"Schema found for table '{table_name}'")
            return [
                bigquery.SchemaField(
                    col["id"].lower(), col["type"], description=col.get("description", "")
                )
                for col in sorted(table["columns"], key=lambda x: x["order"])
            ]
    raise ValueError(f"Schema for table '{table_name}' not found in config.")

# Upload data to BigQuery
def upload_to_bigquery(bucket_name, gcs_file_path, dataset_name, table_name, schema, file_name):
    """Load data from GCS to BigQuery with a given schema."""
    client = bigquery.Client()

    uri = f"gs://{bucket_name}/{gcs_file_path}"
    table_id = f"{client.project}.{dataset_name}.{table_name}"

    # Check if the file_name is "mtx_business_unit.txt" and configure the skip_leading_rows accordingly
    skip_rows = 0 if file_name == "mtx_business_unit.txt" else 1

    job_config = bigquery.LoadJobConfig(
        schema=schema,
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=skip_rows,
        field_delimiter='\t',
        quote_character='',
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE  
    )

    load_job = client.load_table_from_uri(uri, table_id, job_config=job_config)
    load_job.result()

    print(f"Table {table_name} loaded successfully in dataset {dataset_name}.")

# Function to trigger all actions in Dataform workspace using the Dataform API
def run_workflow(project, location, repo_name, workflow_config_name):
    """Trigger the Dataform workflow configuration execution."""
    df_client = dataform_v1beta1.DataformClient()

    repo_uri = f'projects/{project}/locations/{location}/repositories/{repo_name}'
    workflow_config = f'projects/{project}/locations/{location}/repositories/{repo_name}/workflowConfigs/{workflow_config_name}'

    try:
        request = dataform_v1beta1.CreateWorkflowInvocationRequest(
            parent=repo_uri,
            workflow_invocation=dataform_v1beta1.types.WorkflowInvocation(
                workflow_config=workflow_config
            )
        )

        response = df_client.create_workflow_invocation(request=request)
        name = response.name
        print(f"Triggered Dataform workflow '{workflow_config_name}' successfully with invocation name: {name}")
        invocation_id = name.split("/")[-1]
        return invocation_id
    except Exception as e:
        print(f"Failed to trigger Dataform workflow '{workflow_config_name}'. Error: {str(e)}")
        return None

# Check the status of the Dataform workflow invocation
def check_workflow_status(project, location, repo_name, invocation_id):
    df_client = dataform_v1beta1.DataformClient()
    name = f"projects/{project}/locations/{location}/repositories/{repo_name}/workflowInvocations/{invocation_id}"

    while True:
        # Get the state of the workflow invocation
        invocation = df_client.get_workflow_invocation(name=name)
        state = invocation.state
        print(f"Workflow invocation state: {state}")

        # Handle terminal states
        if state == "SUCCEEDED" or state == 2:
            print("Workflow completed successfully.")
            return state  # The workflow completed successfully
        elif state == "FAILED":# or state == 3:
            print("Workflow failed.")
            return state  # The workflow failed
        elif state == "CANCELLED":# or state == 4:
            print("Workflow was cancelled.")
            return state  # The workflow was cancelled

        # Handle the 'CANCELING' state when the workflow is being cancelled
        elif state == "CANCELING":# or state == 5:
            print("Workflow is being cancelled, some actions are still running...")

        # Handle the 'RUNNING' state when the workflow is still in progress
        elif state == "RUNNING" or state == 1:
            print("Workflow still running, waiting for completion...")

        else:
            print(f"Unknown or unhandled state: {state}")
            return state

        # Wait for 30 seconds before the next check
        time.sleep(30)

# Get Power BI access token
def get_powerbi_access_token():
    tenant_id = "8cb50eb8-1bfe-4ad4-b513-6ff79ec168e1"
    client_id = "41835175-8905-4bf5-82aa-88bb448e82ee"
    client_secret = get_secret("power-bi-password-dev-secret")
    resource = "https://analysis.windows.net/powerbi/api"
    
    url = f"https://login.microsoftonline.com/{tenant_id}/oauth2/token"
    headers = {"Content-Type": "application/x-www-form-urlencoded"}
    data = {
        "grant_type": "client_credentials",
        "client_id": client_id,
        "client_secret": client_secret,
        "resource": resource
    }

    response = requests.post(url, headers=headers, data=data)
    if response.status_code == 200:
        return response.json().get("access_token")
    else:
        raise Exception(f"Failed to get Power BI access token: {response.text}")

#  Execute the Power BI refresh
def refresh_powerbi_dataset(dataset_id):
    access_token = get_powerbi_access_token()
    url = f"https://api.powerbi.com/v1.0/myorg/datasets/{dataset_id}/refreshes"

    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }

    body = {
        "notifyOption": "NoNotification" #MailOnFailure if you want to receive an email on failure
    }

    response = requests.post(url, headers=headers, json=body)
    if response.status_code in [200, 202]:
        print(f"Power BI dataset {dataset_id} refresh triggered successfully.")
    else:
        raise Exception(f"Failed to refresh Power BI dataset: {response.text}")

# Entry point for the Cloud Function
def main(event, context):

    # Expected bucket name and prefix
    expected_bucket = "bli-bi-commerciale-test-001-landing"
    prefix = "sftp_tables/"

    print(f"Event: \n{event}")

    # Verify that the bucket matches
    bucket_name = event["bucket"]
    if bucket_name != expected_bucket:
        print(f"Ignored event from bucket '{bucket_name}'. Expected: '{expected_bucket}'.")
        return "Event ignored. Bucket does not match.", 200

    # Retrieve the file name
    gcs_file_path = event["name"]
    if not gcs_file_path.startswith(prefix):
        print(f"Ignored file: {gcs_file_path}. It does not match the required prefix '{prefix}'.")
        return "File not processed. Prefix does not match.", 200

    print(f"Processing file: {gcs_file_path} in bucket: {bucket_name}")

    # # GCS upload
    # bucket_name = "bli-bi-commerciale-test-001-landing"
    # gcs_file_path = f"sftp_tables/{file_name}"
    # upload_to_gcs(bucket_name, file_like_object, gcs_file_path, file_name)

    # BigQuery schema load
    config_path = "sftp_tables/tables_config"
    file_name = os.path.basename(gcs_file_path[len(prefix):])
    table_name = os.path.splitext(file_name)[0].replace(' ', '_').lower()
    table_name_with_prefix = f"board_{table_name}"
    schema = load_schema_from_config(bucket_name, config_path, table_name)

    # Upload to BigQuery
    dataset_name = "landing"
    upload_to_bigquery(bucket_name, gcs_file_path, dataset_name, table_name_with_prefix, schema, file_name)

    # Trigger Dataform workflow
    project = os.getenv("GCP_PROJECT_ID", "bli-bi-commerciale-test-001").replace("env","test")
    location = "europe-west8"
    repo_name = "dataform-bauli-dwh-commerciale"
    invocation_id = run_workflow(project, location, repo_name, table_name_with_prefix)

    # Check the workflow status
    workflow_status = check_workflow_status(project, location, repo_name, invocation_id)

    dataset_id = "0684c9b3-4da7-4a14-993c-3267139707db" # dev

    # Refresh Power BI dataset if the workflow succeeded
    if workflow_status == "SUCCEEDED" or workflow_status == 2:
        refresh_powerbi_dataset(dataset_id)
    else:
        raise Exception(f"Dataform workflow failed with status: {workflow_status}")
    
    return "Process completed successfully.", 200
