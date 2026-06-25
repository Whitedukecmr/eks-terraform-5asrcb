resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.ec2_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  user_data = file("${path.module}/user_data.sh")

  # Active la protection contre la terminaison accidentelle
  disable_api_termination = false

  tags = {
    Name = "${var.project_name}-bastion"
  }
}
