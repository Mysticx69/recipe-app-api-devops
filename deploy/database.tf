##############################################
# Db_Subnet_Group
##############################################
resource "aws_db_subnet_group" "main_subnet_group" {
  name = "db_group-${terraform.workspace}"

  subnet_ids = [
    element(element(module.vpc.private_subnets_id, 1), 0),
    element(element(module.vpc.private_subnets_id, 1), 1)
  ]

  tags = {
    "Name" = "db_group-${terraform.workspace}"
  }
}

##############################################
# RDS Security Group
##############################################
resource "aws_security_group" "rds_sg" {
  description = "Allow access to the RDS database instance."
  name        = "${terraform.workspace}-rds-inbound-access"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "rds_sg"
  }
}

##############################################
# Ingress Rule(s)
##############################################
resource "aws_security_group_rule" "allow_postgre_rds_sg" {
  description              = "Allow port TCP:5432 igress from bastion"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id        = aws_security_group.rds_sg.id
}

resource "aws_security_group_rule" "allow_postgre_rds_sg_2" {
  description              = "Allow port TCP:5432 igress from ecs"
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs_sg.id
  security_group_id        = aws_security_group.rds_sg.id
}

##############################################
# Db Instance
##############################################
resource "aws_db_instance" "main" {
  #checkov:skip=CKV_AWS_161: "Ensure RDS database has IAM authentication enabled"
  #checkov:skip=CKV_AWS_16:  "Ensure all data stored in the RDS is securely encrypted at rest"
  #checkov:skip=CKV_AWS_133: "Ensure that RDS instances has backup policy"
  #checkov:skip=CKV_AWS_129: "Ensure that respective logs of Amazon Relational Database Service (Amazon RDS) are enabled"
  #checkov:skip=CKV_AWS_157: "Ensure that RDS instances have Multi-AZ enabled"
  #checkov:skip=CKV_AWS_118: "Ensure that enhanced monitoring is enabled for Amazon RDS instances"
  #checkov:skip=CKV2_AWS_30: "Ensure Postgres RDS as aws_db_instance has Query Logging enabled"
  identifier                 = "${terraform.workspace}-db"
  db_name                    = "recipe"
  auto_minor_version_upgrade = true
  allocated_storage          = 20
  storage_type               = "gp2"
  engine                     = "postgres"
  engine_version             = "11.15"
  instance_class             = "db.t2.micro"
  db_subnet_group_name       = aws_db_subnet_group.main_subnet_group.name
  password                   = var.db_password
  username                   = var.db_username
  backup_retention_period    = 0
  multi_az                   = false
  skip_final_snapshot        = true
  vpc_security_group_ids     = [aws_security_group.rds_sg.id]

  tags = {
    "Name" = "${terraform.workspace}-db"
  }
}
