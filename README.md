# case-devops

Teknik değerlendirme kapsamında hazırlanan repo: MERN stack (React + Express + MongoDB) ve Python ETL’i containerize edip AWS EKS üzerinde çalıştırmak.

## Repo yapısı

- **mern-project/** — React frontend (`client`) ve Express backend (`server`), MongoDB ile
- **python-project/** — ETL script’i (`ETL.py`), her saat çalışacak şekilde CronJob’da
- **k8s/** — Kubernetes manifest’leri (namespace, deployment, service, ingress, cronjob)
- **infra/terraform/aws/** — EKS, VPC ve node group için Terraform

İki proje birbirinden bağımsız; aynı cluster’da farklı namespace’lerde (mern, python) çalışıyor.

## Lokal çalıştırma

Docker ve Docker Compose yeterli. Projeler ayrı compose dosyalarında.

**MERN (mongo + backend + frontend):**
```bash
docker-compose up --build
```
Frontend: http://localhost:3000  
Backend API: http://localhost:5050

**Python ETL (tek seferlik):**
```bash
docker-compose -f docker-compose.etl.yml up --build
```

## AWS’e deploy

1. **EKS cluster:** `infra/terraform/aws` içinde Terraform (önce `terraform init`, sonra `plan` / `apply`). Detay için klasördeki README’e bak.
2. **kubeconfig:** Apply bittikten sonra `terraform output update_kubeconfig_command` çıktısındaki komutu çalıştır.
3. **ECR:** Client, server ve ETL image’ları için ECR repo’ları oluştur; image’ları **linux/amd64** için build edip push et (Mac ARM kullanıyorsan `docker build --platform linux/amd64` şart).
4. **Manifest’ler:** `k8s/mern/` ve `k8s/python/` içindeki deployment/cronjob’larda image URL’lerini kendi ECR adresinle güncelle, ardından:
   ```bash
   kubectl apply -f k8s/mern/
   kubectl apply -f k8s/python/
   ```

Deploy sırası ve doğrulama komutları için `docs/kubernetes-deploy.md` dosyasına bak.

## CI/CD (GitHub Actions)

`main`’e push edildiğinde MERN ve ETL için ayrı workflow’lar çalışıyor: build → ECR push → EKS’te rollout/apply. GitHub repo’da **Secrets** olarak `AWS_ACCESS_KEY_ID` ve `AWS_SECRET_ACCESS_KEY` tanımlanması yeterli. Detay ve opsiyonel ayarlar: `docs/cicd.md`.

## Kabul kriterleri

- **MERN:** MongoDB bağlı, tüm endpoint’ler ve sayfalar çalışıyor.
- **Python ETL:** `ETL.py` her 1 saatte bir (CronJob) çalışıyor.
