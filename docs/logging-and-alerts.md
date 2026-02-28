# Logging ve Alerts

## EKS control plane logları

Terraform’da EKS cluster için `enabled_cluster_log_types = ["api", "audit", "authenticator"]` tanımlı. Bu loglar otomatik olarak CloudWatch Logs’a gidiyor; log group adları `/aws/eks/<cluster_name>/cluster` altında (api, audit, authenticator). AWS Console → CloudWatch → Log groups’tan bakıyorum.

Container (pod) logları aynı şekilde CloudWatch’a gönderilmek istenirse Fluent Bit veya benzeri bir log dağıtıcı kurulabilir; bu projede sadece control plane logları açık.

## Alarmlar

`infra/terraform/aws/monitoring.tf` içinde:

- **SNS topic:** `case-devops-eks-alerts` — alarm bildirimleri bu topic’e düşüyor.
- **CloudWatch alarm:** EKS metriği `cluster_failed_node_count` ≥ 1 olduğunda tetikleniyor (en az bir node failed). Alarm hem alarm hem ok aksiyonunda SNS topic’i kullanıyor; böylece “alarm” ve “OK” durumunda da bildirim alınabiliyor.
- **E-posta bildirimi:** `alert_email` değişkeni dolu ise (ör. `terraform.tfvars` veya `-var alert_email=...`) bu adrese SNS subscription oluşturuluyor. İlk apply’dan sonra AWS o e-posta adresine confirmation linki gönderiyor; linke tıklanmadan bildirimler aktif olmuyor.

Yeni alarm eklemek için aynı `monitoring.tf` içinde `aws_cloudwatch_metric_alarm` kopyalayıp metric/dimension’ları değiştiriyorum; `alarm_actions = [aws_sns_topic.alerts.arn]` ile aynı topic’e bağlıyorum.
