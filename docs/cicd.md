# CI/CD (GitHub Actions)

`main` dalına push edildiğinde MERN ve ETL için ayrı workflow’lar çalışıyor: build, ECR’e push, EKS’te deploy.

## Gerekli GitHub Secrets

Repo → Settings → Secrets and variables → Actions içinde şunları tanımlıyorum:

| Secret | Açıklama |
|--------|----------|
| `AWS_ACCESS_KEY_ID` | AWS IAM kullanıcısının access key’i (ECR + EKS erişimi olan) |
| `AWS_SECRET_ACCESS_KEY` | Aynı kullanıcının secret key’i |

Bu iki secret yeterli. Workflow içinde `aws sts get-caller-identity` ile hesap ID’si alınıyor, ECR adresi ve registry buna göre oluşturuluyor.

## Workflow’lar

- **`.github/workflows/mern.yml`**  
  `mern-project/` veya `k8s/mern/` değişince: client + server için npm install, client build ve test, ardından her iki servis için Docker image (linux/amd64) build, ECR’e push, EKS’te `kubectl rollout restart deployment mern-client mern-server -n mern`.

- **`.github/workflows/etl.yml`**  
  `python-project/` veya `k8s/python/` değişince: ETL image build (linux/amd64), ECR’e push, `kubectl apply -f k8s/python/cronjob-etl.yaml` ile CronJob güncelleniyor (bir sonraki çalışmada yeni image kullanılır).

## Varsayılanlar ve override

Workflow’larda `env` ile varsayılanlar:

- `AWS_REGION: eu-central-1`
- `EKS_CLUSTER_NAME: case-devops-eks`

Farklı region veya cluster kullanacaksam bu değerleri workflow dosyasındaki `env` bloğundan değiştiriyorum. Gerekirse GitHub’da Environment variables ile de override edilebilir.

## ECR repo’lar

Workflow’lar ECR’e push ederken şu repo adlarını kullanıyor: `case-mern-client`, `case-mern-server`, `case-etl`. Bu repo’ların hesapta önceden oluşturulmuş olması gerekiyor (ilk kurulumda elle veya Terraform ile).

## Not

`k8s/mern/` ve `k8s/python/` içindeki image URL’leri ECR adresini içeriyor. Workflow ECR’e aynı hesabın registry’sine push ettiği için, manifest’lerdeki account ID’nin bu hesaba ait olması yeterli. Repo başka bir hesaba fork edilirse image URL’leri veya Secrets o hesaba göre güncellenmeli.
