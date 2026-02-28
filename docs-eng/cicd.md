# CI/CD (GitHub Actions)

On push to `main`, separate workflows run for MERN and ETL: build, push to ECR, deploy on EKS.

## Required GitHub Secrets

Under Repo → Settings → Secrets and variables → Actions:

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS IAM user access key (with ECR and EKS access) |
| `AWS_SECRET_ACCESS_KEY` | Same user’s secret key |

These two are enough. Workflows use `aws sts get-caller-identity` to get the account ID and build the ECR registry URL.

## Workflows

- **`.github/workflows/mern.yml`**  
  Triggered when `mern-project/` or `k8s/mern/` changes: npm install, client build and test, then Docker image build (linux/amd64) for both services, push to ECR, and `kubectl rollout restart deployment mern-client mern-server -n mern` on EKS.

- **`.github/workflows/etl.yml`**  
  Triggered when `python-project/` or `k8s/python/` changes: ETL image build (linux/amd64), push to ECR, and `kubectl apply -f k8s/python/cronjob-etl.yaml` so the next run uses the new image.

## Defaults and override

Workflow `env` defaults:

- `AWS_REGION: eu-central-1`
- `EKS_CLUSTER_NAME: case-devops-eks`

Change these in the workflow file’s `env` block for a different region or cluster, or override via GitHub Environment variables.

## ECR repositories

Workflows push to these repository names: `case-mern-client`, `case-mern-server`, `case-etl`. They must exist in the account (created manually or via Terraform on first setup).

## Note

Image URLs in `k8s/mern/` and `k8s/python/` point to ECR. As long as the workflow pushes to the same account’s registry, the account ID in the manifests must match. If the repo is forked to another account, update image URLs or Secrets accordingly.
