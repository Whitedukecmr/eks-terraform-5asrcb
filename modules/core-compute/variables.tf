variable "project_name" {
  description = "Préfixe utilisé pour nommer les ressources"
  type        = string
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
}

variable "vpc_cidr" {
  description = "Bloc CIDR du VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "ec2_type" {
  description = "Type d'instance EC2 (t2.micro ou t3.micro)"
  type        = string
  default     = "t3.micro"
}

variable "eks_cluster_name" {
  description = "Nom du cluster EKS — utilisé pour les tags Kubernetes sur les subnets"
  type        = string
}
