# CI/CD, Observability & Security Runbook

This project implements a CI/CD pipeline for a Node.js Express application and extends it with a complete Observability and Security stack: Prometheus, Grafana, AWS CloudWatch Logs, CloudTrail, and GuardDuty.

## Prerequisites

1.  **Jenkins Server**: Installed with Pipeline, Git, Credentials Binding, Docker Pipeline, and SSH Agent plugins.
2.  **Ansible**: Installed on the Jenkins server to handle deployment configuration.
3.  **Docker**: Installed on Jenkins and configured for the `jenkins` user.
4.  **AWS EC2**: Provisioned using the provided Terraform module.
5.  **Docker Hub**: Account and repository created.

## Setup Instructions

### 1. Infrastructure Provisioning (Terraform)

1.  `cd infra/terraform`
2.  Update `terraform.tfvars` with your settings (Region, Instance Type, Key Name, `cloudtrail_bucket_name`). Ensure the S3 bucket name is globally unique.
3.  `terraform init && terraform apply -auto-approve`
4.  Note the `web_server_public_ip`.

### 2. Jenkins Credentials

You must create the following credentials in Jenkins (**Manage Jenkins** -> **Manage Credentials**):

*   **registry_creds**: Kind "Username with password" (Docker Hub credentials).
*   **ec2_ssh**: Kind "SSH Username with private key" (Username: `ec2-user`, Private Key: your `updated` key found in Downloads).

### 3. Local Jenkins with ngrok (Optional)

If running Jenkins on `localhost:8080`, use ngrok to enable GitHub Webhooks:

1.  Run `ngrok http 8080`.
2.  Update **Jenkins URL** in System Settings with the ngrok address.
3.  Add a Webhook in GitHub: `https://<ngrok-id>.ngrok-free.app/github-webhook/`.

### 4. Pipeline Configuration

1.  Create a **Pipeline** job in Jenkins.
2.  Select "This project is parameterized" and add the following String Parameters:
    *   `DOCKER_HUB_USER`: Your Docker Hub username.
    *   `DOCKER_HUB_REPO`: Your repository name.
    *   `EC2_PUBLIC_IP`: Your Elastic IP from `terraform output web_server_public_ip`
    *   `APP_VERSION`: The version tag for the image (e.g., `1.0.0`).
3.  Enable **GitHub hook trigger for GITScm polling** under Build Triggers.
4.  Select **Pipeline script from SCM** (Git) and set the **Script Path** to `Jenkinsfile`.

## Deployment with Ansible

The pipeline uses modular Ansible roles for idempotent deployments:

*   `infra/ansible/roles/docker`: Handles Docker installation and system configuration.
*   `infra/ansible/roles/webapp`: Handles application lifecycle (pulling and running containers). Docker is configured to stream container logs to CloudWatch Logs via the `awslogs` driver.
*   `infra/ansible/deploy.yml`: The main playbook orchestrated by Jenkins.

## Pipeline Best Practices Implemented

*   **Configuration as Code**: Using Ansible for reliable, idempotent container management.
*   **Modular Architecture**: Ansible roles ensure separation of system setup and app deployment.
*   **Credential Masking**: Using `credentials()` and `sshagent` ensures secrets are never leaked in logs.
*   **Zero Hardcoding**: Every variable is configurable via Jenkins parameters.
*   **Build Hooks**: `options` block includes `buildDiscarder` and `timestamps` for better log management.
*   **Clean Workspace**: Uses `cleanWs()` in the `post` block to save disk space on Jenkins agents.

## Verification
1. Access the application via the static Elastic IP (or your provisioned EIP):
   - App health: `http://<EIP>/`
   - Metrics: `http://<EIP>/metrics`
2. CloudWatch Logs:
   - Navigate to CloudWatch > Log groups > `/docker/web-app` and confirm logs from the container are streaming.
3. CloudTrail:
   - Verify trail exists and is enabled (multi‑region). Confirm S3 bucket has encrypted log objects and lifecycle policy.
4. GuardDuty:
   - Confirm the GuardDuty detector is enabled. Optionally, generate sample findings from the GuardDuty console.
5. Prometheus & Grafana (local or same EC2 host):
   - Local (recommended for demo): `cd monitoring && docker compose up -d`.
     - Prometheus: `http://localhost:9090`
     - Grafana: `http://localhost:3001` (admin/admin)
   - Grafana includes a pre-provisioned data source and dashboard: "Web App - Latency, RPS, Error Rate".
6. Alert Test (>5% error rate):
   - Generate 20 requests with 2–3 forced 500 errors (e.g., temporarily add a route throwing 500 or scale load testers).
   - Prometheus rule `HighErrorRate` should fire within ~2 minutes; view under Prometheus Alerts or in Grafana alerting (if configured).

Screenshots to capture (place under `docs/screenshots/`):
- Prometheus targets page showing `web-app` and `node-exporter` up.
- Grafana dashboard with latency/RPS/error panels populated.
- An active alert (HighErrorRate) in Prometheus or Grafana.
- CloudWatch Log Group `/docker/web-app` with recent log streams.
- GuardDuty sample findings and CloudTrail events in the S3 bucket.

## Cleanup

*   **Containers**: Handled automatically on EC2 via Ansible after each deployment.
*   **Infrastructure**: Run `terraform destroy -auto-approve` inside the `infra/terraform/` directory.
*   **Local stack**: `cd monitoring && docker compose down -v`.

## Artifact Map (Submission)

- Prometheus config: `monitoring/prometheus/prometheus.yml`
- Alert rules: `monitoring/prometheus/alerts.yml`
- Grafana dashboard JSON: `monitoring/grafana/dashboards/webapp-observability.json`
- Grafana provisioning: `monitoring/grafana/provisioning/...`
- Screenshots: `docs/screenshots/`
- Report: `docs/REPORT.md`
