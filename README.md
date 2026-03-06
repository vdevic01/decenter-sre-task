# decenter-sre-task

Solution for the technical task for the SRE interview process at Decenter.

## App

The application source is in the `app/` directory (NestJS).

### Run locally

Prerequisites:

- Node.js `>=20.18.0`
- npm `>=10`

Steps:

```bash
cd app
npm install
npm run start:dev
```

The app starts on `http://localhost:3000` by default.

Environment variables:

- `PORT`: Port the NestJS app listens on. Default: `3000`.
- `HOST`: Network interface the app binds to. Default: `localhost`.

For containers and ECS tasks, set `HOST=0.0.0.0` so the app is reachable from outside the container.

Useful endpoints:

- `GET /health` - Returns service health status (`ok`) and current timestamp.
- `GET /metrics` - Exposes Prometheus metrics (currently total HTTP request count).

### Run with Docker

Build image from repository root:

```bash
docker build -t decenter-sre-app ./app
```

Run container:

```bash
docker run -d -p 80:3000 -e HOST=0.0.0.0 --name decenter-sre decenter-sre-app
```

App URL: `http://localhost:80`

Container healthcheck:

- The image has a built-in Docker `HEALTHCHECK` that calls `GET /health` every 30 seconds.
- Check status with `docker ps` (or `docker inspect decenter-sre --format "{{.State.Health.Status}}"`).

Optional custom port:

```bash
docker run --rm -p 8080:8080 -e PORT=8080 -e HOST=0.0.0.0 --name decenter-sre-app decenter-sre-app
```

## CI/CD

Main branch CI is defined in `.github/workflows/ci-main.yml`.

### What `ci-main` does

- **When it runs**:
  - On pushes to `main` when files under `app/**` change.
  - Manually via `workflow_dispatch`.
- **Permissions**:
  - `contents: read` to read repository code.
  - `packages: write` to publish images to GHCR.
- **Build process**:
  - Checks out repository code.
  - Builds image metadata (`ghcr.io/<owner>/decenter-sre`) and short commit SHA tag.
  - Installs `nerdctl`, SOCI snapshotter, and BuildKit on the GitHub runner.
  - Logs in to GHCR using `${{ secrets.GITHUB_TOKEN }}`.
  - Builds Docker image from `./app/Dockerfile`.
  - Converts image for SOCI (`--soci`) and pushes two tags:
    - `<ghcr-repo>:<short_sha>`
    - `<ghcr-repo>:latest`
- **Result**:
  - The latest application image is published to GHCR and ready to be used by Terraform/ECS (`image` variable in `terraform.tfvars`).
  - Workflow prints a short summary with commit SHA and published image tags.

### SOCI

SOCI (Seekable OCI) is a way to make container images start faster on ECS/Fargate by using lazy loading.

- Without SOCI, ECS usually waits for the full image to download before the container starts.
- With SOCI, ECS can start the task sooner and fetch image data on demand, which reduces cold-start time.
- In this repository, `ci-main` prepares a SOCI-enabled image (`nerdctl image convert --soci ...`) before pushing it, so ECS can benefit from faster task launches.

For this specific application, SOCI is realistically an overkill because the service is small and startup is already fast. It is included here as a proof of concept to demonstrate how SOCI can be integrated into a CI/CD pipeline for larger images where scaling speed is important.

## Terraform

Terraform configuration is in the `terraform/` directory.

### Design

This setup keeps state remote, infrastructure modular, and deployment flow easy to reason about.

- **Remote state**: Terraform state is stored in an S3 backend, so state is shared and consistent across runs.
- **State locking**: S3 lockfile locking is enabled (`use_lockfile = true`) to prevent concurrent `plan/apply` runs from corrupting state.
- **Module split**:
  - `alb_module` creates the public ALB, listener, target group, and ALB security group.
  - `ecs_module` creates the ECS cluster, task definition, service, log group, and execution role.
- **Traffic flow**: Internet traffic goes to ALB on port `80`, ALB forwards to the ECS service target group, and tasks serve the app on `container_port`.
- **Demo networking choice**: For simplicity, ECS is deployed in the default VPC.
- **Production recommendation**: Run ECS tasks in private subnets of a custom VPC and use NAT gateways for outbound access. This is required so tasks can pull images from GHCR and publish logs to CloudWatch without exposing tasks directly.
- **Image access assumption**: Current setup assumes the GHCR image repository is public.

If GHCR is private, store a GitHub PAT (`read:packages`) in Secrets Manager and use ECS `repositoryCredentials`.

Example: store GHCR credentials in Secrets Manager:

```hcl
resource "aws_secretsmanager_secret" "ghcr" {
  name = "ghcr-pull-credentials"
}

resource "aws_secretsmanager_secret_version" "ghcr" {
  secret_id = aws_secretsmanager_secret.ghcr.id
  secret_string = jsonencode({
    username = "your-github-username"
    password = "ghp_xxx_with_read_packages"
  })
}
```

Example: wire the secret into ECS task definition container config:

```hcl
# ecs_module/variables.tf
variable "repository_credentials_secret_arn" {
  type    = string
  default = null
}

# ecs_module/main.tf (inside container_definitions object)
repositoryCredentials = var.repository_credentials_secret_arn == null ? null : {
  credentialsParameter = var.repository_credentials_secret_arn
}
```

### Prerequisites

- Terraform CLI installed (recommended `>= 1.5`)
- AWS credentials available in the shell where Terraform is executed

If you use access keys in PowerShell, set them before running Terraform:

```powershell
$env:AWS_ACCESS_KEY_ID="<your-access-key>"
$env:AWS_SECRET_ACCESS_KEY="<your-secret-key>"
$env:AWS_REGION="eu-central-1"
```

### Step-by-step

1. Go to Terraform directory:

```bash
cd terraform
```

2. Create/update `terraform.tfvars` with deployment values, for example:

```hcl
environment    = "dev"
image          = "ghcr.io/vdevic01/decenter-sre:latest"
container_name = "app"
desired_count  = 1
container_port = 3000
```

3. Initialize Terraform

```bash
terraform init
```

4. Review execution plan:

```bash
terraform plan
```

5. Apply infrastructure:

```bash
terraform apply
```

After apply, Terraform prints outputs such as the ALB DNS name.
