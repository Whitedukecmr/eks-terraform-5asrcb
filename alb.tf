# ═══════════════════════════════════════════════════════════
# ALB — Security Group
# ═══════════════════════════════════════════════════════════

resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = module.core_compute.vpc_id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# ═══════════════════════════════════════════════════════════
# ALB — Application Load Balancer
# ═══════════════════════════════════════════════════════════

resource "aws_lb" "this" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  internal           = false

  security_groups = [aws_security_group.alb_sg.id]
  # L'ALB est placé dans les subnets PUBLICS des 3 AZ
  subnets = module.core_compute.public_subnet_ids

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ═══════════════════════════════════════════════════════════
# ALB — Target Group (pointe vers l'EC2 bastion)
# ═══════════════════════════════════════════════════════════

resource "aws_lb_target_group" "this" {
  name     = "${var.project_name}-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.core_compute.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.project_name}-alb-tg"
  }
}

# ═══════════════════════════════════════════════════════════
# ALB — Attachement EC2 → Target Group
# ═══════════════════════════════════════════════════════════

resource "aws_lb_target_group_attachment" "ec2" {
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = module.core_compute.ec2_id
  port             = 80
}

# ═══════════════════════════════════════════════════════════
# ALB — Listener HTTP:80 → forward vers le Target Group
# ═══════════════════════════════════════════════════════════

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = {
    Name = "${var.project_name}-alb-listener-http"
  }
}
