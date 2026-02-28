# Dağıtım süreci

## Önkoşullar

- AWS hesabı, AWS CLI yapılandırılmış (`aws configure`).
- Terraform ≥ 1.0, kubectl, Docker.
- GitHub repo; CI/CD için GitHub Secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY).

## 1. Altyapının kurulması (Terraform)

1. `infra/terraform/aws` dizinine gidilir.
2. `terraform init` ile provider ve modüller indirilir.
3. `terraform plan` ile oluşturulacak kaynaklar incelenir.
4. `terraform apply` ile VPC, subnet, internet gateway, route table, EKS cluster, node group, IAM roller, (opsiyonel) SNS topic ve e-posta subscription, CloudWatch alarm oluşturulur.
5. Apply çıktısındaki `update_kubeconfig_command` kullanılarak yerel kubeconfig güncellenir; `kubectl get nodes` ile node’ların Ready olması beklenir.

Detay: [infra/terraform/aws/README.md](../infra/terraform/aws/README.md).

## 2. ECR ve image’lar

1. ECR’de repo’lar oluşturulur: `case-mern-client`, `case-mern-server`, `case-etl`.
2. `aws ecr get-login-password … | docker login …` ile registry’e giriş yapılır.
3. Her uygulama için image **linux/amd64** platformunda build edilir (Mac ARM kullanılıyorsa `--platform linux/amd64` zorunludur).
4. Image’lar ilgili ECR repo’lara tag’lenip push edilir.
5. `k8s/mern/` ve `k8s/python/` içindeki manifest’lerdeki image URL’leri bu ECR adresleriyle güncellenir.

Detay: [kubernetes-deploy.md](kubernetes-deploy.md).

## 3. Kubernetes’e uygulama dağıtımı

1. Repo kökünden `kubectl apply -f k8s/mern/` ve `kubectl apply -f k8s/python/` çalıştırılır.
2. İlk apply’da namespace henüz yoksa deployment/cronjob “namespace not found” verebilir; namespace’ler oluştuktan sonra aynı komutlar tekrarlanır.
3. `kubectl get pods -n mern` ve `kubectl get pods -n python` ile pod’ların Running ve Ready olması kontrol edilir.
4. Gerekirse `kubectl logs`, `kubectl describe pod` ile hata ayıklanır.

Detay: [kubernetes-deploy.md](kubernetes-deploy.md).

## 4. CI/CD’nin devreye alınması

1. GitHub repo’da Settings → Secrets and variables → Actions altında `AWS_ACCESS_KEY_ID` ve `AWS_SECRET_ACCESS_KEY` tanımlanır.
2. `main` dalına ilgili path’lere push yapıldığında MERN ve ETL workflow’ları sırasıyla build, test (MERN’de), image build/push ve EKS’te rollout/apply yapar.
3. Workflow’lar ve secret kullanımı: [cicd.md](cicd.md).

## Altyapı kurulumu – Terraform ile oluşturulan kaynaklar

- **VPC:** CIDR 10.0.0.0/16; DNS hostname ve destek açık.
- **Subnet’ler:** İki public subnet (farklı availability zone’larda); EKS için gerekli tag’ler atanmış.
- **Internet gateway ve route table:** Public subnet’lerin internete çıkışı.
- **EKS cluster:** 1.29; control plane logları CloudWatch’a (api, audit, authenticator).
- **EKS node group:** ON_DEMAND; instance tipleri t2/t3 small–medium; scaling min/desired/max.
- **IAM:** Cluster rolü (EKS policy’leri), node rolü (worker, CNI, ECR read).
- **SNS topic:** Alarm bildirimleri için.
- **SNS e-posta subscription:** `alert_email` değişkeni doldurulduysa; ilk apply sonrası e-postadan confirmation gerekir.
- **CloudWatch alarm:** EKS metriği `cluster_failed_node_count` ≥ 1; aksiyon olarak SNS topic.

## Önemli yapılandırma noktaları

- **Terraform değişkenleri:** `variables.tf` (region, cluster_name, node sayıları, instance tipleri, alert_email). Override: `terraform.tfvars` veya `-var`.
- **Kubernetes manifest’ler:** Namespace, Deployment, Service, Ingress (MERN), CronJob (ETL); image URL’leri ECR ile uyumlu olmalı.
- **GitHub Actions:** Workflow’larda `AWS_REGION`, `EKS_CLUSTER_NAME` env; AWS kimlik bilgisi yalnızca Secrets üzerinden.
