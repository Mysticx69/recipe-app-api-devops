###########################
# Call My Networking Module
###########################
module "Networking" {
  source               = "git::https://github.com/Mysticx69/TPcloudAWS.git//terraform/modules/Networking?ref=v1.0.4"
  environment          = "udemy"
  vpc_cidr             = "10.150.0.0/16"
  public_subnets_cidr  = ["10.150.1.0/24", "10.150.2.0/24"]
  private_subnets_cidr = ["10.150.10.0/24", "10.150.20.0/24"]
  availability_zones   = local.availability_zones
}
