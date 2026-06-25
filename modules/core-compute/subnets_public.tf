# ═══════════════════════════════════════════════════════════
# Subnets PUBLICS — 1 par AZ
#
# CORRECTION : map_public_ip_on_launch = true  (manquait dans la version originale)
# CORRECTION : tag kubernetes.io/role/elb = "1"  (requis pour que l'ALB
#              et l'EKS Load Balancer Controller trouvent les subnets publics)
# ═══════════════════════════════════════════════════════════

locals {
  # CIDRs des subnets publics — /24 dans le VPC /16
  public_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 1),  # ex: 10.2.1.0/24
    cidrsubnet(var.vpc_cidr, 8, 2),  # ex: 10.2.2.0/24
    cidrsubnet(var.vpc_cidr, 8, 3),  # ex: 10.2.3.0/24
  ]
}

resource "aws_subnet" "public" {
  count = 3

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true  # Les instances EC2 dans ces subnets reçoivent une IP publique

  tags = {
    Name                                        = "${var.project_name}-public-subnet-${count.index + 1}"
    "kubernetes.io/role/elb"                    = "1"   # Requis pour l'ALB controller EKS
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "public" {
  count = 3

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
