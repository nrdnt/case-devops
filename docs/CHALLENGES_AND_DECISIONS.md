# Karşılaşılan zorluklar ve alınan kararlar

## EKS Kubernetes sürümü

- **Sorun:** Bazı bölgelerde belirli minor sürümler “unsupported” veya node group AMI’si “not supported” hatası veriyordu (ör. 1.28 AMI, 1.26/1.27 sürüm kaldırılmış).
- **Çözüm:** Cluster’ı bölgede desteklenen sürüme sabitledim (1.29); node group’ta `ami_type = "AL2_x86_64"` kullandım. Sürüm değişikliği yaparken downgrade yapılamayacağı için Terraform’daki version değerini mevcut cluster ile uyumlu tuttum.

## Node group’ta instance oluşmaması

- **Sorun:** Node group “Creating” durumunda kalıyordu; EC2 instance’lar ayağa kalkmıyordu (kapasite veya bölge kısıtı).
- **Çözüm:** `node_instance_types` listesini genişlettim (t3.small, t3.medium, t2.small, t2.medium); böylece hangi tipinde kapasite varsa AWS onu kullandı.

## Mac (ARM) ile build edilen image’ların EKS’te çalışmaması

- **Sorun:** Pod’lar ImagePullBackOff sonrası çekilen image’da “exec format error” veriyordu.
- **Sebep:** Yerel Docker Mac ARM (arm64) için build ediyordu; EKS node’lar x86_64.
- **Çözüm:** Tüm uygulama image’larını `docker build --platform linux/amd64` ile build edip ECR’e push ettim; GitHub Actions workflow’larında da aynı platform kullanıldı.

## İlk kubectl apply’da “namespace not found”

- **Sorun:** Aynı dizinde toplu apply yapıldığında deployment/cronjob bazen namespace henüz API’de görünmeden oluşturulmaya çalışılıyordu.
- **Çözüm:** Namespace’ler oluştuktan sonra aynı `kubectl apply -f k8s/mern/` ve `kubectl apply -f k8s/python/` komutları tekrar çalıştırıldı; ikinci apply’da deployment’lar başarıyla oluştu.

## Manifest’lerdeki image URL’lerinin güncel kalmaması

- **Sorun:** Deployment’lar hâlâ placeholder image (`your-account-id.dkr.ecr...`) çekmeye çalışıyordu.
- **Sebep:** Manifest dosyaları diskte güncellenmişti ancak cluster’a yeniden apply edilmemişti.
- **Çözüm:** Image URL’leri ECR ile güncellendikten sonra `kubectl apply -f k8s/mern/deployment-client.yaml` (ve server) tekrar çalıştırıldı; gerektiğinde `kubectl rollout restart deployment ...` ile yeni image’lar çekildi.

## Backend’in MongoDB’ye bağlanmadan başlaması (startup order)

- **Sorun:** mern-server pod’ları bazen CrashLoopBackOff’a düşüyordu; log’larda Mongo connection refused veya timeout görülüyordu.
- **Sebep:** Server container’ı Mongo’dan önce ayağa kalkıyor; Kubernetes’te `depends_on` sadece pod scheduling için, container’ların “hazır” olmasını beklemiyor.
- **Çözüm:** Deployment’ta readinessProbe ve livenessProbe ile server’ın 5050 portunda cevap vermesini beklettim. Mongo aynı namespace’te kısa sürede erişilebilir hale geliyor; server 1–2 restart sonrası sağlıklı çalışıyor. İstersen init container veya retry logic de eklenebilir.

## Terraform apply sırasında EKS sürüm uyumsuzluğu

- **Sorun:** Monitoring (SNS, alarm) ekledikten sonra apply’da “Unsupported Kubernetes minor version update from 1.29 to 1.28” hatası alındı.
- **Sebep:** Cluster 1.29’daydı; Terraform’da 1.28 yazıyordu. EKS sürüm düşürülmez.
- **Çözüm:** `eks.tf` içindeki `version` değerini 1.29 ile eşitledim; state ile kodun senkron kalması için `terraform plan` ile kontrol etmek işe yarıyor.

## GitHub Actions’ta EKS’e erişim ve rollout timeout

- **Sorun:** Workflow’da `kubectl rollout status` adımında bazen timeout veya “context deadline exceeded” alındı.
- **Sebep:** Node’lar yeni image’ı çekerken süre uzayabiliyor; varsayılan timeout kısa kalıyordu.
- **Çözüm:** `kubectl rollout status ... --timeout=120s` ile süreyi artırdım. Production’da OIDC ile role assumption ve daha kısıtlı IAM tercih edilebilir.

## ECR’den image çekme yetkisi (ImagePullBackOff / access denied)

- **Sorun:** Image’lar ECR’de olmasına rağmen pod’lar ImagePullBackOff veya “pull access denied” veriyordu.
- **Sebep:** EKS node IAM rolüne ECR okuma yetkisi eklenmemişti.
- **Çözüm:** Terraform’da node rolüne `AmazonEC2ContainerRegistryReadOnly` policy’sini attach ettim; image’lar aynı hesaptaki ECR’de olduğu için node’lar sorunsuz çekiyor. Farklı hesap kullanılacaksa ECR policy’de cross-account erişim tanımlanmalı.
