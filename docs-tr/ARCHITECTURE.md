# Mimari

## Genel bakış

- **Bulut:** AWS (eu-central-1 / Frankfurt)
- **Orkestrasyon:** Kubernetes (EKS – Elastic Kubernetes Service)
- **Konteyner registry:** AWS ECR
- **CI/CD:** GitHub Actions (build, test, image push, EKS deploy)
- **İki bağımsız uygulama:** MERN stack (Proje 1) ve Python ETL (Proje 2); aynı EKS cluster içinde farklı namespace’lerde çalışır.

## Bileşenler

| Bileşen | Açıklama |
|--------|----------|
| **VPC** | 10.0.0.0/16; 2 public subnet (farklı AZ’lerde). |
| **EKS cluster** | Tek control plane; Kubernetes API ve scheduler. |
| **EKS node group** | EC2 (t2/t3 small–medium); MERN ve ETL pod’ları burada çalışır. |
| **Namespace `mern`** | React frontend (Nginx), Express backend, MongoDB. |
| **Namespace `python`** | ETL CronJob (her saat başı çalışan Job). |
| **ECR** | case-mern-client, case-mern-server, case-etl image’ları. |
| **GitHub Actions** | MERN ve ETL için ayrı workflow’lar; push → build → ECR push → EKS’te güncelleme. |
| **CloudWatch** | EKS control plane logları (api, audit, authenticator); alarmlar SNS’e bağlı. |
| **SNS** | Kritik alarm bildirimleri (opsiyonel e-posta subscription). |

## Veri akışı – MERN

- Kullanıcı → Ingress/ALB (tanımlıysa) veya port-forward → **mern-client** (React static, Nginx:80).
- **mern-client** → **mern-server** (Express:5050) → **mongo** (MongoDB:27017).
- Tümü `mern` namespace’inde; servisler ClusterIP ile birbirine DNS adıyla erişir.

## Veri akışı – Python ETL

- CronJob `etl-cronjob` (schedule: `0 * * * *`) her saat başı bir Job oluşturur.
- Job tek pod çalıştırır; image ECR’deki `case-etl:latest`. Pod biter, Job tamamlanır.
