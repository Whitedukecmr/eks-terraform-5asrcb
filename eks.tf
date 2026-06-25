# ═══════════════════════════════════════════════════════════
# EKS — Cluster Control Plane
# ═══════════════════════════════════════════════════════════

resource "aws_eks_cluster" "this" {
  name     = var.eks_cluster_name
  version  = var.eks_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = concat(
      module.core_compute.public_subnet_ids,
      module.core_compute.private_subnet_ids
    )
    endpoint_public_access  = true
    endpoint_private_access = true
    security_group_ids      = [module.core_compute.eks_cluster_sg_id]
  }

  # Active les logs du control plane vers CloudWatch
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
  ]

  tags = {
    Name = var.eks_cluster_name
  }
}

# ═══════════════════════════════════════════════════════════
# EKS — Node Group (EC2 managées par l'utilisateur)
# ═══════════════════════════════════════════════════════════

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.eks_cluster_name}-ng"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  # Les nœuds sont déployés dans les subnets PRIVÉS
  subnet_ids = module.core_compute.private_subnet_ids

  instance_types = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_readonly,
  ]

  tags = {
    Name = "${var.eks_cluster_name}-node-group"
  }
}

# ═══════════════════════════════════════════════════════════
# EKS — Addons obligatoires
# ═══════════════════════════════════════════════════════════

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "vpc-cni"
  # resolve_conflicts_on_update préserve la config en cas de mise à jour
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [aws_eks_node_group.this]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [aws_eks_node_group.this]
}
