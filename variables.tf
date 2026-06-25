variable "region" {
  description = "Région AWS cible (multi-région compatible)"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Nom de l'environnement (ex: dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Nom du projet — utilisé comme préfixe pour toutes les ressources"
  type        = string
  default     = "5asrcb"
}

variable "vpc_cidr" {
  description = "Bloc CIDR du VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "ec2_type" {
  description = "Type d'instance EC2 bastion (t2.micro ou t3.micro selon la région)"
  type        = string
  default     = "t3.micro"
}

# ── EKS ─────────────────────────────────────────────────

variable "eks_cluster_name" {
  description = "Nom du cluster EKS"
  type        = string
  default     = "eks-5asrcb"
}

variable "eks_version" {
  description = "Version Kubernetes du cluster EKS"
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "Type d'instance pour les nœuds EKS"
  type        = string
  default     = "t3.micro"
}

variable "node_desired_size" {
  description = "Nombre de nœuds souhaité dans le node group"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Nombre minimum de nœuds dans le node group"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Nombre maximum de nœuds dans le node group"
  type        = number
  default     = 3
}
