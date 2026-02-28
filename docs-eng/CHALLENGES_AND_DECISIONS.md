# Challenges faced and decisions taken

## EKS Kubernetes version

- **Issue:** In some regions certain minor versions were “unsupported” or the node group AMI returned “not supported” (e.g. 1.28 AMI, 1.26/1.27 deprecated).
- **Solution:** Pinned the cluster to a supported version (1.29) and set `ami_type = "AL2_x86_64"` on the node group. Kept the Terraform version in sync with the live cluster, since EKS does not support downgrades.

## Node group not launching instances

- **Issue:** Node group stayed in “Creating”; EC2 instances never appeared (capacity or region limits).
- **Solution:** Expanded `node_instance_types` (t3.small, t3.medium, t2.small, t2.medium) so AWS can use whichever type has capacity.

## Images built on Mac (ARM) failing on EKS

- **Issue:** Pods showed “exec format error” after ImagePullBackOff.
- **Cause:** Local Docker built for Mac ARM (arm64); EKS nodes are x86_64.
- **Solution:** Built all application images with `docker build --platform linux/amd64` and pushed to ECR; same platform used in GitHub Actions workflows.

## “namespace not found” on first kubectl apply

- **Issue:** When applying a directory at once, deployment/cronjob sometimes ran before the namespace was visible in the API.
- **Solution:** Re-ran the same `kubectl apply -f k8s/mern/` and `kubectl apply -f k8s/python/` after namespaces existed; the second apply succeeded.

## Manifest image URLs not updated in cluster

- **Issue:** Deployments still tried to pull placeholder images (`your-account-id.dkr.ecr...`).
- **Cause:** Manifests were updated on disk but not re-applied to the cluster.
- **Solution:** Re-ran `kubectl apply` for the deployment manifests after fixing image URLs; used `kubectl rollout restart deployment ...` when needed to pull new images.

## Backend starting before MongoDB (startup order)

- **Issue:** mern-server pods sometimes went into CrashLoopBackOff with Mongo connection refused or timeout in logs.
- **Cause:** Server container started before Mongo; Kubernetes `depends_on` only affects pod scheduling, not container readiness.
- **Solution:** Used readinessProbe and livenessProbe so the server is considered ready only when responding on port 5050. Mongo becomes available shortly in the same namespace; server stabilizes after 1–2 restarts. Init container or retry logic could be added if needed.

## EKS version mismatch during Terraform apply

- **Issue:** After adding monitoring (SNS, alarm), apply failed with “Unsupported Kubernetes minor version update from 1.29 to 1.28”.
- **Cause:** Cluster was on 1.29; Terraform had 1.28. EKS does not support version downgrade.
- **Solution:** Set `version` in `eks.tf` to 1.29. Running `terraform plan` after larger changes helps keep state and code in sync.

## GitHub Actions access to EKS and rollout timeout

- **Issue:** Workflow sometimes hit timeout or “context deadline exceeded” on `kubectl rollout status`.
- **Cause:** Nodes can take a while to pull the new image; default timeout was too short.
- **Solution:** Increased timeout with `kubectl rollout status ... --timeout=120s`. For production, OIDC-based role assumption and tighter IAM are preferable.

## ECR image pull permission (ImagePullBackOff / access denied)

- **Issue:** Pods showed ImagePullBackOff or “pull access denied” even though images existed in ECR.
- **Cause:** EKS node IAM role did not have ECR read permission.
- **Solution:** Attached `AmazonEC2ContainerRegistryReadOnly` to the node role in Terraform; images are in the same account’s ECR so nodes can pull. For a different account, ECR policy would need cross-account access.
