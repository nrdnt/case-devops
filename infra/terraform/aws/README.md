# AWS EKS Altyapısı (Terraform)

Bu klasör EKS cluster, VPC ve node group’u tanımlar.

## Önkoşullar

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) yapılandırılmış (`aws configure` ile access key, secret, region)
- EKS için yeterli IAM yetkisi

## Kullanım

```bash
cd infra/terraform/aws

# Bağımlılıkları indir
terraform init

# Planı incele
terraform plan

# Uygula (onay sonrası)
terraform apply
```

Apply sonrası `kubectl` kullanmak için:

```bash
aws eks update-kubeconfig --region <region> --name <cluster_name>
```

`terraform output update_kubeconfig_command` ile tam komutu görebilirsiniz.

## Değişkenler

- `aws_region` (varsayılan: `eu-central-1`)
- `cluster_name` (varsayılan: `case-devops-eks`)
- `node_desired_size`, `node_min_size`, `node_max_size`
- `node_instance_types` (varsayılan: `["t3.medium"]`)

Override için `terraform.tfvars` veya `-var` kullanılabilir.

## State

Şu an state lokal `terraform.tfstate` dosyasındadır. Production için S3 backend önerilir.
