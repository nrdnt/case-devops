# case-devops

MERN stack (React, Express, MongoDB) ve Python ETL uygulamasının containerize edilip AWS EKS üzerinde çalıştırıldığı teknik değerlendirme projesi.

---

## İçerik

- **Proje 1 (MERN):** React frontend, Express backend, MongoDB — Kubernetes’te aynı namespace’te.
- **Proje 2 (Python ETL):** `ETL.py` — CronJob ile her saat çalışır.

İki proje birbirinden bağımsızdır; aynı cluster’da farklı namespace’lerde (`mern`, `python`) çalışır.

---

## Repo yapısı

| Klasör / dosya | Açıklama |
|----------------|----------|
| `mern-project/` | React client + Express server (MongoDB ile) |
| `python-project/` | ETL script’i |
| `k8s/` | Kubernetes manifest’leri (namespace, deployment, service, ingress, cronjob) |
| `infra/terraform/aws/` | EKS, VPC, node group için Terraform |
| `.github/workflows/` | MERN ve ETL için CI/CD (GitHub Actions) |
| `docs-tr/` | Belgeler (Türkçe) |
| `docs-eng/` | Documentation (English) |
| `docker-compose.yml` | MERN’i yerelde çalıştırmak için |
| `docker-compose.etl.yml` | ETL’i yerelde çalıştırmak için |

---

## Hızlı başlangıç

### Local Çalıştırma

**MERN:**
```bash
docker-compose up --build
```
- Frontend: http://localhost:3000  
- Backend: http://localhost:5050  

**Python ETL:**
```bash
docker-compose -f docker-compose.etl.yml up --build
```

### AWS’e Deploy

1. `infra/terraform/aws` içinde `terraform init` → `terraform apply`
2. `terraform output update_kubeconfig_command` çıktısıyla kubeconfig güncellenmelidir.
3. ECR repo’ları oluşturulmalıdır; image’ları **linux/amd64** ile build alınıp push'lanmalıdır.
4. `k8s/` manifest’lerindeki image URL’lerini ECR adresi ile güncellenmelidir.
5. `kubectl apply -f k8s/mern/` ve `kubectl apply -f k8s/python/`

Aşağıda kurulum ve hazırlanması istenen belgeler mevcuttur.

---

## Belgeler / Documentation

Belgeler iki dilde hazırlanmıştır: 

**Türkçe** (`docs-tr/`) ve **İngilizce** (`docs-eng/`).

**Case belgeleri (TR) / Case docs (EN):**

- [**Mimari**](docs-tr/ARCHITECTURE.md) · [Architecture](docs-eng/ARCHITECTURE.md) — Bileşenler, veri akışı / Components, data flow.
- [**Dağıtım süreci**](docs-tr/DEPLOYMENT_PROCESS.md) · [Deployment process](docs-eng/DEPLOYMENT_PROCESS.md) — Önkoşullar, Terraform, ECR, K8s, CI/CD.
- [**Karşılaşılan zorluklar**](docs-tr/CHALLENGES_AND_DECISIONS.md) · [Challenges and decisions](docs-eng/CHALLENGES_AND_DECISIONS.md) — Sorunlar ve çözümleri / Issues and solutions.

**Teknik Dökümanlar (TR) / Technical Documents (EN):**

- [Kubernetes deploy (TR)](docs-tr/kubernetes-deploy.md) · [Kubernetes deploy (EN)](docs-eng/kubernetes-deploy.md) — kubeconfig, ECR, manifest apply, kontrol.
- [CI/CD (TR)](docs-tr/cicd.md) · [CI/CD (EN)](docs-eng/cicd.md) — GitHub Secrets, workflow’lar.
- [Logging ve uyarılar (TR)](docs-tr/logging-and-alerts.md) · [Logging and alerts (EN)](docs-eng/logging-and-alerts.md) — EKS logları, CloudWatch, SNS.
- [Terraform (EKS)](infra/terraform/aws/README.md) — Terraform kullanımı, değişkenler, state.

---

## Sonuç

Tüm testler yapılmıştır. 

- **MERN:** MongoDB bağlı; tüm endpoint’ler ve sayfalar çalışıyor.
- **Python ETL:** `ETL.py` her 1 saatte bir (CronJob) çalışıyor.

