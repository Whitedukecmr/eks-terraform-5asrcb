terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # BONUS: Décommenter ce bloc après avoir créé le bucket S3 manuellement
  # backend "s3" {
  #   bucket = "votre-bucket-tfstate"
  #   key    = "eks-5asrcb/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "EKS-5ASRCB"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

# ─────────────────────────────────────────────────────────
# Module local core-compute  (VPC, Subnets, SG, EC2)
# ─────────────────────────────────────────────────────────
module "core_compute" {
  source = "./modules/core-compute"

  project_name    = var.project_name
  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  ec2_type        = var.ec2_type
  eks_cluster_name = var.eks_cluster_name
}
