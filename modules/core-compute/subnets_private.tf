# ═══════════════════════════════════════════════════════════
# EIP + NAT Gateway (1 seul NAT pour économiser, dans le subnet public AZ-a)
# ═══════════════════════════════════════════════════════════

resource "aws_eip" "nat" {
  domain = "vpc"

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id   # Placé dans le premier subnet public

  depends_on = [aws_internet_gateway.this]

  tags = {
    Name = "${var.project_name}-nat-gw"
  }
}

# ═══════════════════════════════════════════════════════════
# Route table privée → Internet via NAT
# ═══════════════════════════════════════════════════════════

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

# ═══════════════════════════════════════════════════════════
# Subnets PRIVÉS — 1 par AZ
#
# CORRECTION : tag kubernetes.io/role/internal-elb = "1"
#              (requis pour que EKS place les nœuds dans ces subnets)
# ═══════════════════════════════════════════════════════════

locals {
  private_cidrs = [
    cidrsubnet(var.vpc_cidr, 8, 10),  # ex: 10.2.10.0/24
    cidrsubnet(var.vpc_cidr, 8, 20),  # ex: 10.2.20.0/24
    cidrsubnet(var.vpc_cidr, 8, 30),  # ex: 10.2.30.0/24
  ]
}

resource "aws_subnet" "private" {
  count = 3

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                            = "${var.project_name}-private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb"               = "1"  # Requis pour les LB internes EKS
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

resource "aws_route_table_association" "private" {
  count = 3

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
