##############################################
# Load Balancer
##############################################
resource "aws_lb" "api" {
  #checkov:skip=CKV_AWS_150: "No need to ensure that LB cant be deleted"
  #checkov:skip=CKV_AWS_91: "Ensure the ELBv2 (Application/Network) has access logging enabled"
  #checkov:skip=CKV2_AWS_20: "Ensure that ALB redirects HTTP requests into HTTPS ones"
  #checkov:skip=CKV2_AWS_28: "Ensure public facing ALB are protected by WAF"
  name                       = "${terraform.workspace}-main"
  load_balancer_type         = "application"
  drop_invalid_header_fields = true

  subnets = [
    element(element(module.vpc.public_subnets_id, 1), 0),
    element(element(module.vpc.public_subnets_id, 1), 1)
  ]

  security_groups = [aws_security_group.lb.id]
}

##############################################
# Target Group
##############################################
resource "aws_lb_target_group" "api" {
  name        = "${terraform.workspace}-api"
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
  port        = 8000

  health_check {
    path = "/admin/login/"
  }
}

##############################################
# LB Listener
##############################################
resource "aws_lb_listener" "api" {
  #checkov:skip=CKV_AWS_2: "Ensure ALB protocol is HTTPS"
  #checkov:skip=CKV_AWS_103: "Ensure that load balancer is using at least TLS 1.2"
  load_balancer_arn = aws_lb.api.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

##############################################
# LB Security Group
##############################################
resource "aws_security_group" "lb" {
  description = "Allow access to Application Load Balancer"
  name        = "lb_sg"
  vpc_id      = module.vpc.vpc_id
}

##############################################
# Ingress Rule(s)
##############################################
resource "aws_security_group_rule" "allow_http_lb" {
  description       = "Allow HTTP igress"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["176.147.76.8/32"]
  security_group_id = aws_security_group.lb.id
}

##############################################
# Egress Rule(s)
##############################################
resource "aws_security_group_rule" "allow_8000_lb" {
  description       = "Allow 8000 egress"
  type              = "egress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb.id
}
