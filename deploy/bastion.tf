##################
# Retrieve Aws AMI
##################
data "aws_ami" "amazon_linux" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }
  owners = ["amazon"]
}


######################
# Iam Role For Bastion
######################
resource "aws_iam_role" "bastion" {
  name               = "iamrole-bastion"
  assume_role_policy = file("./templates/bastion/instance-profile-policy.json")
}

##################
#Policy Attachment
##################
resource "aws_iam_role_policy_attachment" "bastion_attach_policy" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

#################
#Instance Profile
#################
resource "aws_iam_instance_profile" "bastion" {
  name = "bastion-instance-profile"
  role = aws_iam_role.bastion.name
}

##########
# Key Pair
##########
resource "aws_key_pair" "bastion_kp" {
  key_name   = "recipe-app-api-devops-bastion"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHjoaUsZBPUAXIhv9JL8riFean8nEXIXVN1d61mC1CO8PTG6BcPrrY0W1JPtDAsU+x4TBJV9EQm7vYXAZEIXe7KwkeTL61alU8U6mG6nCXllinSysJGPoFjCwdzgcu58h6M7WL3nODbZh6e/9PPLmP/Ufb1S1RQdOoTQMJaHh0bo9AIN8JmPjBOIJitGRYs4tFyVHjGU4YGOw3evDwW9qITcJ/uJSvxqQy81zQ4tM+pdW41t+Lm1qsEOlrqibvj2yPU0XuyHDlUXW8XGKzQFrMJNgBopdpWaE8Hk8egljH6TVjFkWhVzg1H60DzZm/oZDjEnmFxnp7hMPhE9n49cb3rnowWiE8av1bmT89/R10sg+WpPT53EXOMb5BK6lescDv2T/fD2/b3oVDsO4fnFEdYqA2uoqZN9cQw66owzZAKqezfi3RiR2wVYAafe78G3n6X3W3PslTGxRDkcQ/mtcIICRQTPiJkqlIA4iORtPBsl2vJIBrciWxK/QDgiOxD/M= user@DESKTOP-JS87L9H"
}

################
# Bastion Server
################
resource "aws_instance" "bastion" {
  #checkov:skip=CKV_AWS_135: "Ensure that EC2 is EBS optimized" => Not supported
  #checkov:skip=CKV_AWS_126: "Ensure that detailed monitoring is enabled for EC2 instances" => Not supported
  #checkov:skip=CKV_AWS_88: "EC2 instance should not have public IP." => Needed

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  user_data                   = file("./templates/bastion/user-data.sh")
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  key_name                    = aws_key_pair.bastion_kp.id
  subnet_id                   = element(element(module.vpc.public_subnets_id, 1), 0)
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted = true
  }

  tags = {
    "Name" = "bastion-${terraform.workspace}"
  }
}

########################
# Bastion Security Group
########################
resource "aws_security_group" "bastion_sg" {
  description = "Control bastion ingress and egress access"
  name        = "${terraform.workspace}-bastion_sg"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "bastion_sg"
  }
}

#################
# Ingress Rule(s)
#################
resource "aws_security_group_rule" "allow_ssh_ingress_bastion_sg" {
  description       = "Allow ssh igress"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["176.147.76.8/32"]
  security_group_id = aws_security_group.bastion_sg.id
}

################
# Egress Rule(s)
################
resource "aws_security_group_rule" "allow_http_egress_bastion_sg" {
  description       = "Allow http egress"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "allow_https_egress_bastion_sg" {
  description       = "Allow https egress"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "allow_postgres_egress_bastion_sg" {
  description       = "Allow postgres egress"
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [element(element(module.vpc.private_subnets_cidr, 1), 0), element(element(module.vpc.private_subnets_cidr, 1), 1)]
  security_group_id = aws_security_group.bastion_sg.id
}
