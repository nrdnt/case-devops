output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID used by EKS"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "Subnet IDs used by EKS"
  value       = aws_subnet.public[*].id
}

# kubeconfig güncellemek için (terraform apply sonrası çalıştırılır):
# aws eks update-kubeconfig --region <region> --name <cluster_name>
output "update_kubeconfig_command" {
  description = "Run this command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "sns_topic_arn" {
  description = "Alarm bildirimleri için SNS topic ARN"
  value       = aws_sns_topic.alerts.arn
}
