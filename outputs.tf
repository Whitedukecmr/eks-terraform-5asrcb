# ─── Réseau ─────────────────────────────────────────────────
output "vpc_id" {
  description = "ID du VPC créé"
  value       = module.core_compute.vpc_id
}

output "public_subnet_ids" {
  description = "IDs des 3 subnets publics"
  value       = module.core_compute.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs des 3 subnets privés"
  value       = module.core_compute.private_subnet_ids
}

# ─── EC2 ─────────────────────────────────────────────────────
output "ec2_public_ip" {
  description = "IP publique de l'instance EC2 bastion"
  value       = module.core_compute.ec2_public_ip
}

# ─── EKS ─────────────────────────────────────────────────────
output "eks_cluster_name" {
  description = "Nom du cluster EKS"
  value       = aws_eks_cluster.this.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint API du cluster EKS"
  value       = aws_eks_cluster.this.endpoint
}

output "eks_cluster_version" {
  description = "Version Kubernetes du cluster"
  value       = aws_eks_cluster.this.version
}

output "eks_cluster_certificate_authority" {
  description = "Certificate Authority du cluster (pour kubeconfig)"
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

# ─── ALB ─────────────────────────────────────────────────────
output "alb_dns_name" {
  description = "DNS public de l'Application Load Balancer"
  value       = aws_lb.this.dns_name
}

# ─── Commande kubeconfig ─────────────────────────────────────
output "kubeconfig_command" {
  description = "Commande pour configurer kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.this.name}"
}
