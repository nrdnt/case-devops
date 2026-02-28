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
| `docker-compose.yml` | MERN’i yerelde çalıştırmak için |
| `docker-compose.etl.yml` | ETL’i yerelde çalıştırmak için |

---

## Hızlı başlangıç

### Yerel çalıştırma

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

### AWS’e deploy (özet)

1. `infra/terraform/aws` içinde `terraform init` → `terraform apply`
2. `terraform output update_kubeconfig_command` çıktısıyla kubeconfig güncelle
3. ECR repo’ları oluştur; image’ları **linux/amd64** ile build edip push et
4. `k8s/` manifest’lerindeki image URL’lerini ECR adresinle güncelle
5. `kubectl apply -f k8s/mern/` ve `kubectl apply -f k8s/python/`

Detaylı adımlar için aşağıdaki belgelere bakın.

---

## Belgeler

### Case belgeleri

Dağıtım süreci, mimari ve karşılaşılan zorlukların olduğu dökümanlar:

- [**Mimari**](docs/ARCHITECTURE.md) — Bileşenler, veri akışı (MERN ve ETL).
- [**Dağıtım süreci**](docs/DEPLOYMENT_PROCESS.md) — Önkoşullar, Terraform, ECR, Kubernetes deploy, CI/CD ve yapılandırma.
- [**Karşılaşılan zorluklar ve alınan kararlar**](docs/CHALLENGES_AND_DECISIONS.md) — Yaşanan sorunlar ve çözümleri.

### Teknik belgeler

Uygulama adımları ve ayarlar için dökümanlar:

- [Kubernetes deploy](docs/kubernetes-deploy.md) — kubeconfig, ECR login/build/push, manifest apply, kontrol komutları.
- [CI/CD](docs/cicd.md) — GitHub Secrets, workflow’lar, ECR repo isimleri.
- [Logging ve uyarılar](docs/logging-and-alerts.md) — EKS logları, CloudWatch alarm, SNS, e-posta bildirimi.
- [Terraform (EKS)](infra/terraform/aws/README.md) — Terraform kullanımı, değişkenler, state.

---

## Sonuç

- **MERN:** MongoDB bağlı; tüm endpoint’ler ve sayfalar çalışıyor.
- **Python ETL:** `ETL.py` her 1 saatte bir (CronJob) çalışıyor.
