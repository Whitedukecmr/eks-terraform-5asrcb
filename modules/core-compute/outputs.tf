output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs des 3 subnets publics"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs des 3 subnets privés"
  value       = aws_subnet.private[*].id
}

output "ec2_id" {
  description = "ID de l'instance EC2 bastion"
  value       = aws_instance.bastion.id
}

output "ec2_public_ip" {
  description = "IP publique de l'EC2 bastion"
  value       = aws_instance.bastion.public_ip
}

output "ec2_sg_id" {
  description = "ID du security group EC2"
  value       = aws_security_group.ec2.id
}

output "eks_cluster_sg_id" {
  description = "ID du security group additionnel EKS"
  value       = aws_security_group.eks_cluster.id
}
