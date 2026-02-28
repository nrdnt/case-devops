# Logging and alerts

## EKS control plane logs

In Terraform, the EKS cluster has `enabled_cluster_log_types = ["api", "audit", "authenticator"]`. These logs go to CloudWatch Logs; log groups are under `/aws/eks/<cluster_name>/cluster` (api, audit, authenticator). View them in AWS Console → CloudWatch → Log groups.

To send container (pod) logs to CloudWatch as well, you can add a log shipper such as Fluent Bit; this project only enables control plane logs.

## Alarms

In `infra/terraform/aws/monitoring.tf`:

- **SNS topic:** `case-devops-eks-alerts` — alarm notifications are published here.
- **CloudWatch alarm:** Fires when EKS metric `cluster_failed_node_count` ≥ 1 (at least one node failed). Both alarm and OK actions use the SNS topic so you get notified when the alarm triggers and when it resolves.
- **Email notification:** If `alert_email` is set (e.g. in `terraform.tfvars` or `-var alert_email=...`), an SNS subscription is created for that address. After the first apply, AWS sends a confirmation link to that email; notifications are not active until the link is clicked.

To add more alarms, duplicate `aws_cloudwatch_metric_alarm` in `monitoring.tf`, change metric/dimensions, and set `alarm_actions = [aws_sns_topic.alerts.arn]` to use the same topic.
