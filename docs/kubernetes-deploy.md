# Kubernetes’e deploy

EKS cluster hazır olduktan sonra MERN ve Python ETL’i nasıl deploy ettiğimi burada topladım.

## Önce kubeconfig

Cluster’a bağlanmak için kubeconfig’i güncelliyorum. Terraform apply bittikten sonra:

```bash
cd infra/terraform/aws
terraform output update_kubeconfig_command
```

Çıkan komutu çalıştırıyorum (örnek: `aws eks update-kubeconfig --region eu-central-1 --name case-devops-eks`). Ardından `kubectl get nodes` ile node’ların Ready olmasını bekliyorum.

## ECR ve image’lar

Image’lar ECR’de olmalı. Repo’ları oluşturup image’ları push ediyorum:

```bash
aws ecr create-repository --repository-name case-mern-client --region eu-central-1
aws ecr create-repository --repository-name case-mern-server --region eu-central-1
aws ecr create-repository --repository-name case-etl --region eu-central-1
```

Login:

```bash
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com
```

Build ve push (Mac ARM kullanıyorsam mutlaka `--platform linux/amd64`, yoksa EKS node’larda exec format error alıyorum):

```bash
cd /path/to/case-devops

docker build --platform linux/amd64 -t <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/case-mern-client:latest ./mern-project/client
docker push <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/case-mern-client:latest

docker build --platform linux/amd64 -t <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/case-mern-server:latest ./mern-project/server
docker push <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/case-mern-server:latest

docker build --platform linux/amd64 -t <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/case-etl:latest ./python-project
docker push <ACCOUNT_ID>.dkr.ecr.eu-central-1.amazonaws.com/case-etl:latest
```

`k8s/mern/deployment-client.yaml`, `deployment-server.yaml` ve `k8s/python/cronjob-etl.yaml` içindeki image satırını kendi ECR adresimle değiştiriyorum.

## Manifest’leri uygulama

Repo kökünden (case-devops):

```bash
kubectl apply -f k8s/mern/
kubectl apply -f k8s/python/
```

İlk apply’da namespace henüz yoksa deployment’lar “namespace not found” verebiliyor; namespace’ler oluştuktan sonra aynı komutları bir kez daha çalıştırıyorum.

## Kontroller

```bash
kubectl get pods -n mern
kubectl get pods -n python
kubectl get svc -n mern
```

Pod’lar ImagePullBackOff ise image ECR’de mi ve tag doğru mu kontrol ediyorum. CrashLoopBackOff ise `kubectl logs -n mern deployment/mern-server --tail=50` gibi log’lara bakıyorum.

CronJob için manuel test:

```bash
kubectl create job -n python --from=cronjob/etl-cronjob etl-manual-1
kubectl logs -n python job/etl-manual-1 -f
```

Ingress kullanıyorsam `kubectl get ingress -n mern` ile ALB adresini alıyorum; DNS’in hazır olması birkaç dakika sürebiliyor.
