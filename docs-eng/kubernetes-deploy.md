# Deploy to Kubernetes

Steps used to deploy MERN and Python ETL once the EKS cluster is ready.

## Update kubeconfig first

After Terraform apply:

```bash
cd infra/terraform/aws
terraform output update_kubeconfig_command
```

Run the printed command (e.g. `aws eks update-kubeconfig --region eu-central-1 --name case-devops-eks`). Then run `kubectl get nodes` and wait for nodes to become Ready.

## ECR and images

Images must exist in ECR. Create repositories and push images:

```bash
aws ecr create-repository --repository-name case-mern-client --region eu-central-1
aws ecr create-repository --repository-name case-mern-server --region eu-central-1
aws ecr create-repository --repository-name case-etl --region eu-central-1
```

Login:

```bash
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com
```

Build and push (use `--platform linux/amd64` on Mac ARM to avoid exec format error on EKS nodes):

```bash
cd /path/to/case-devops

docker build --platform linux/amd64 -t <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/case-mern-client:latest ./mern-project/client
docker push <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/case-mern-client:latest

docker build --platform linux/amd64 -t <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/case-mern-server:latest ./mern-project/server
docker push <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/case-mern-server:latest

docker build --platform linux/amd64 -t <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/case-etl:latest ./python-project
docker push <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/case-etl:latest
```

Update the image line in `k8s/mern/deployment-client.yaml`, `deployment-server.yaml`, and `k8s/python/cronjob-etl.yaml` with your ECR URL.

## Apply manifests

From repo root (case-devops):

```bash
kubectl apply -f k8s/mern/
kubectl apply -f k8s/python/
```

If namespaces are not ready yet, deployments may fail with “namespace not found”; run the same commands again after namespaces exist.

## Verification

```bash
kubectl get pods -n mern
kubectl get pods -n python
kubectl get svc -n mern
```

For ImagePullBackOff, verify the image exists in ECR and the tag is correct. For CrashLoopBackOff, check logs with e.g. `kubectl logs -n mern deployment/mern-server --tail=50`.

Manual CronJob test:

```bash
kubectl create job -n python --from=cronjob/etl-cronjob etl-manual-1
kubectl logs -n python job/etl-manual-1 -f
```

For Ingress, run `kubectl get ingress -n mern` to get the ALB address; DNS may take a few minutes to become ready.
