# EKS altyapısı (Terraform)

Bu klasörde EKS cluster, VPC ve node group tanımları var. Cluster’ı ilk kez kurarken buradan başlıyorum.

**Gereksinimler:** Terraform 1.0+, AWS CLI yapılandırılmış (`aws configure`), EKS için yetkili IAM.

**Temel akış:**

```bash
cd infra/terraform/aws
terraform init
terraform plan   # ne oluşacak görmek için
terraform apply  # onaylayıp bekliyorum (~10–15 dk)
```

Apply bittikten sonra kubectl ile bağlanmak için:

```bash
terraform output update_kubeconfig_command
```

Çıkan komutu kopyalayıp çalıştırıyorum (ör. `aws eks update-kubeconfig --region eu-central-1 --name case-devops-eks`). Sonra `kubectl get nodes` ile node’ların Ready olmasını kontrol ediyorum.

**Değişkenler:** `variables.tf` içinde region (varsayılan eu-central-1), cluster adı, node sayısı ve instance tipleri var. Alarm bildirimi için `alert_email` (opsiyonel) tanımlanırsa SNS’e e-posta subscription ekleniyor; detay için `docs/logging-and-alerts.md`. Farklı bölge veya boyut için `terraform.tfvars` ya da `-var` kullanıyorum.

**State:** Şu an local state kullanıyorum (`terraform.tfstate`). Prod’da S3 backend kullanmak daha doğru.
