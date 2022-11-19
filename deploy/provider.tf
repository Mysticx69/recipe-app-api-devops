provider "aws" {
  region = "eu-west-3"

  default_tags {
    tags = {
      Author      = "Antoine Sterna"
      Environment = terraform.workspace
      ManagedBy   = "Terraform"
      Project     = "Udemy"
    }
  }
}

terraform {
  required_version = "~>1.3.4"

  required_providers {
    aws      = "~>4"
    template = "~>2.2"
  }
}

locals {
  region             = "eu-west-3"
  availability_zones = ["${local.region}a", "${local.region}b", "${local.region}c"]
}

data "aws_region" "current" {}
