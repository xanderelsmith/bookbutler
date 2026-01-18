# Serverpod Deployment Guide

This guide covers the main ways to deploy your Serverpod project to production.

## 1. Serverpod Cloud (Private Beta)
Serverpod Cloud is the official managed service for Serverpod, currently in private beta.
-   **Zero Configuration**: Automates SSL, load balancing, and database provisioning.
-   **Deployment**: Runs via `scloud deploy` command.
-   **Access**: You must [join the waitlist](https://serverpod.dev) to get access.

## 2. Globe.dev (Recommended for Ease of Use)

Globe.dev is a platform specifically designed for Dart and Serverpod applications. It handles much of the complexity for you.

### Steps:
1.  **Create a Globe account** at [globe.dev](https://globe.dev).
2.  **Install the Globe CLI**:
    ```bash
    dart pub global activate globe_cli
    ```
3.  **Login**:
    ```bash
    globe login
    ```
4.  **Deploy Server**:
    Navigate to your server directory (`project_thera_server`) and run:
    ```bash
    globe deploy
    ```
    - Follow the prompts to create a project.
    - Globe will automatically detect it's a Serverpod project.
    - Set your environment variables (like database passwords) in the Globe dashboard.

5.  **Deploy Client**:
    - Update your Flutter app's `client` setup to point to the new Globe URL.
    - You can also deploy your Flutter web app via Globe if desired.

## 2. AWS / GCP (Official Terraform Scripts)

Serverpod comes with built-in Terraform scripts to set up a complete scalable infrastructure on AWS or Google Cloud Platform. This is recommended for serious production applications requiring auto-scaling, load balancers, and managed databases.

### Prerequisites:
-   AWS or GCP account.
-   [Terraform installed](https://developer.hashicorp.com/terraform/downloads).
-   [Serverpod CLI installed](https://docs.serverpod.dev/get-started/install).

### Steps:
1.  **Configure Terraform**:
    You will find Terraform scripts in your server project under `deploy/aws` or `deploy/gcp` (if you enabled them during creation). If not, you can download the standard templates from the [Serverpod repository](https://github.com/serverpod/serverpod/tree/main/templates/serverpod_templates/projectNAME_server/deploy).
    
2.  **Set Variables**:
    -   Update `config.auto.tfvars` with your project name, region, and other settings.
    -   Ensure you have your cloud credentials set up locally (e.g., via `aws configure` or `gcloud auth`).

3.  **Initialize and Apply**:
    ```bash
    cd deploy/aws  # or deploy/gcp
    terraform init
    terraform apply
    ```
    - This will create the VPC, Database (RDS/Cloud SQL), Auto-scaling groups, Load Balancers, etc.
    - It saves the output (IP addresses, domain names) which you'll need.

4.  **Github Actions**:
    -   Serverpod projects often come with a `.github/workflows/deployment-aws.yml` template.
    -   Commit your code to GitHub.
    -   Configure GitHub Secrets with the credentials provided by the Terraform output.
    -   Pushing to the `deployment` branch will trigger the build and deploy.

## 3. Self-Hosted (Docker)

You can deploy Serverpod anywhere that runs Docker (DigitalOcean, Linode, generic VPS).

### Steps:
1.  **Build Docker Image**:
    Your project has a `Dockerfile` in `project_thera_server/`.
    ```bash
    docker build -t my-serverpod-app .
    ```

2.  **Run with Docker Compose**:
    On your server, use a `docker-compose.yaml` similar to your local one but tuned for production:
    -   **Password Security**: Pass DB passwords via environment variables, do not hardcode them.
    -   **Database**: Use a managed managed database or a persistent volume for Postgres.
    -   **Redis**: Required if you use caching or Future calls.

3.  **Reverse Proxy**:
    -   Set up Nginx or Traefik in front of your Serverpod container to handle SSL (HTTPS) and route traffic to ports 8080 (API) and 8082 (Web).

## Important Configuration Notes

### 1. `config/production.yaml`
Ensure your `project_thera_server/config/production.yaml` is configured correctly:
-   **Database Host**: Provide the IP/hostname of your production database.
-   **Database Port**: Usually 5432.
-   **Database Name**: `project_thera`.
-   **Database User**: `postgres` (or your production user).
-   **Database Password**: **DO NOT STORE THIS IN THE FILE**. Use environment variable `SERVERPOD_DATABASE_PASSWORD`.

### 2. Environment Variables
In production, you should set these environment variables (availability depends on platform):
-   `SERVERPOD_DATABASE_PASSWORD`: The password for your production database.
-   `SERVERPOD_PASSWORDS_PATH`: Path to the passwords file (if used).

### 3. Migrations
When deploying for the first time or updating schema:
-   Ensure migrations are applied. The standard Serverpod Docker container often attempts to apply migrations on startup if configured, or you can run `dart run bin/main.dart --apply-migrations` manually (or via a startup script) before starting the server.
