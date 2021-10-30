provider "aws" {
  region = var.region
}

terraform {
  backend "local" {
    path = "/home/cloud_user/infracode/terraform/01-vpc/vpc.tfstate"
  }
}

locals {
  # The usage of the specific kubernetes.io/cluster/* resource tags below are required
  # for EKS and Kubernetes to discover and manage networking resources
  # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
  name    = "${var.name}-${var.env}"
}

module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=master"
  name   = local.name
  cidr   = "172.31.0.0/16"

  azs             = var.availability_zones
  private_subnets = ["172.31.1.0/24", "172.31.2.0/24", "172.31.3.0/24"]
  public_subnets  = ["172.31.4.0/24", "172.31.5.0/24", "172.31.6.0/24"]

  // To create eks cluster in private subnets, we must enable nat gateway
  enable_nat_gateway   = false 
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  } 
  public_route_table_tags = {
    env = var.env
  }

  private_route_table_tags = {
    env = var.env
  }

  default_network_acl_name = local.name
  default_network_acl_tags = {
    env = var.env
  }

  igw_tags = {
    env = var.env
  }

  nat_eip_tags = {
    env = var.env
  }

  nat_gateway_tags = {
    env = var.env
  }
}

