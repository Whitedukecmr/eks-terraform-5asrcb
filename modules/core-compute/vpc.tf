# ═══════════════════════════════════════════════════════════
# VPC
# ═══════════════════════════════════════════════════════════

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true   # Requis pour EKS
  enable_dns_hostnames = true   # Requis pour EKS

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ═══════════════════════════════════════════════════════════
# Internet Gateway (pour les subnets publics)
# ═══════════════════════════════════════════════════════════

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ═══════════════════════════════════════════════════════════
# Route table publique → Internet via IGW
# ═══════════════════════════════════════════════════════════

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}
