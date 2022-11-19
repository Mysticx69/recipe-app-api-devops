#############
# ECS Cluster
#############
resource "aws_ecs_cluster" "main" {
  name = "${terraform.workspace}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

#####################
# Iam policy and role
#####################
resource "aws_iam_policy" "task_execution_role_policy" {
  name        = "${terraform.workspace}-task-exec-role-policy"
  path        = "/"
  description = "Allow retrieving images and adding to logs"
  policy      = file("./templates/ecs/task-exec-role.json")
}

resource "aws_iam_role" "task_execution_role" {
  name               = "${terraform.workspace}-task-exec-role"
  assume_role_policy = file("./templates/ecs/assume-role-policy.json")
}

resource "aws_iam_role_policy_attachment" "task_execution_role" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.task_execution_role_policy.arn
}

resource "aws_iam_role" "app_iam_role" {
  name               = "${terraform.workspace}-api-task"
  assume_role_policy = file("./templates/ecs/assume-role-policy.json")
}

##################
# CloudWatch Group
##################
resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  #checkov:skip=CKV_AWS_158: "Ensure that CloudWatch Log Group is encrypted by KMS"
  name              = "${terraform.workspace}-api"
  retention_in_days = 90
}

####################
# Template file data
####################
data "template_file" "api_container_definitions" {
  template = file("templates/ecs/container-definitions.json.tpl")
  vars = {
    app_image         = var.ecr_image_api
    proxy_image       = var.ecr_image_proxy
    django_secret_key = var.django_secret_key
    db_host           = aws_db_instance.main.address
    db_name           = aws_db_instance.main.db_name
    db_user           = aws_db_instance.main.username
    db_pass           = aws_db_instance.main.password
    log_group_name    = aws_cloudwatch_log_group.ecs_task_logs.name
    log_group_region  = data.aws_region.current.name
    allowed_hosts     = aws_lb.api.dns_name
  }
}

##################
# Task Definition
#################
resource "aws_ecs_task_definition" "api" {
  family                   = "${terraform.workspace}-api"
  container_definitions    = data.template_file.api_container_definitions.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.task_execution_role.arn
  task_role_arn            = aws_iam_role.app_iam_role.arn

  volume {
    name = "static"
  }
}

####################
# ECS Security Group
####################
resource "aws_security_group" "ecs_sg" {
  description = "Access for the ECS service"
  name        = "${terraform.workspace}-ecs-service"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "ecs_sg"
  }
}

#################
# Ingress Rule(s)
#################
resource "aws_security_group_rule" "allow_8000_ecs_sg" {
  description              = "Allow port TCP:8000 igress"
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb.id
  security_group_id        = aws_security_group.ecs_sg.id
}

################
# Egress Rule(s)
################
resource "aws_security_group_rule" "allow_https_ecs_sg" {
  description       = "Allow HTTPS egress"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ecs_sg.id
}

resource "aws_security_group_rule" "allow_postgres_ecs_sg" {
  description       = "Allow postgress egress"
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [element(element(module.vpc.private_subnets_cidr, 1), 0), element(element(module.vpc.private_subnets_cidr, 1), 1)]
  security_group_id = aws_security_group.ecs_sg.id
}

#############
# Ecs Service
#############
resource "aws_ecs_service" "api" {
  name             = "${terraform.workspace}-api"
  cluster          = aws_ecs_cluster.main.name
  task_definition  = aws_ecs_task_definition.api.family
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {

    subnets = [
      element(element(module.vpc.private_subnets_id, 1), 0),
      element(element(module.vpc.private_subnets_id, 1), 1)
    ]

    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "proxy"
    container_port   = "8000"
  }
}
