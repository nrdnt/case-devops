# Deployment process

## Prerequisites

- AWS account, AWS CLI configured (`aws configure`).
- Terraform ≥ 1.0, kubectl, Docker.
- GitHub repo; for CI/CD: GitHub Secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY).

## 1. Infrastructure setup (Terraform)

1. Change to `infra/terraform/aws`.
2. Run `terraform init` to download providers and modules.
3. Run `terraform plan` to review resources to be created.
4. Run `terraform apply` to create VPC, subnets, internet gateway, route table, EKS cluster, node group, IAM roles, (optional) SNS topic and email subscription, CloudWatch alarm.
5. Use the `update_kubeconfig_command` from the apply output to update local kubeconfig; wait for nodes to become Ready with `kubectl get nodes`.

Details: [infra/terraform/aws/README.md](../infra/terraform/aws/README.md).

## 2. ECR and images

1. Create ECR repositories: `case-mern-client`, `case-mern-server`, `case-etl`.
2. Log in to the registry with `aws ecr get-login-password … | docker login …`.
3. Build each application image for **linux/amd64** (required when using Mac ARM: `--platform linux/amd64`).
4. Tag and push images to the corresponding ECR repositories.
5. Update image URLs in manifests under `k8s/mern/` and `k8s/python/` to match your ECR addresses.

Details: [kubernetes-deploy.md](kubernetes-deploy.md).

## 3. Deploy applications to Kubernetes

1. From repo root run `kubectl apply -f k8s/mern/` and `kubectl apply -f k8s/python/`.
2. If namespaces are not ready yet, the first apply may fail with “namespace not found”; run the same commands again after namespaces exist.
3. Check pods with `kubectl get pods -n mern` and `kubectl get pods -n python` until they are Running and Ready.
4. Use `kubectl logs`, `kubectl describe pod` for troubleshooting.

Details: [kubernetes-deploy.md](kubernetes-deploy.md).

## 4. Enabling CI/CD

1. In the GitHub repo, under Settings → Secrets and variables → Actions, define `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
2. Pushing to `main` on the relevant paths triggers MERN and ETL workflows: build, test (MERN), image build/push, and rollout/apply on EKS.
3. Workflows and secret usage: [cicd.md](cicd.md).

## Infrastructure – Resources created by Terraform

- **VPC:** CIDR 10.0.0.0/16; DNS hostnames and support enabled.
- **Subnets:** Two public subnets (different availability zones); EKS-required tags applied.
- **Internet gateway and route table:** Outbound internet for public subnets.
- **EKS cluster:** 1.29; control plane logs to CloudWatch (api, audit, authenticator).
- **EKS node group:** ON_DEMAND; instance types t2/t3 small–medium; min/desired/max scaling.
- **IAM:** Cluster role (EKS policies), node role (worker, CNI, ECR read).
- **SNS topic:** For alarm notifications.
- **SNS email subscription:** If `alert_email` is set; confirmation email required after first apply.
- **CloudWatch alarm:** EKS metric `cluster_failed_node_count` ≥ 1; action is SNS topic.

## Important configuration points

- **Terraform variables:** `variables.tf` (region, cluster_name, node counts, instance types, alert_email). Override via `terraform.tfvars` or `-var`.
- **Kubernetes manifests:** Namespace, Deployment, Service, Ingress (MERN), CronJob (ETL); image URLs must match ECR.
- **GitHub Actions:** Workflows use `AWS_REGION`, `EKS_CLUSTER_NAME` env; AWS credentials only via Secrets.
