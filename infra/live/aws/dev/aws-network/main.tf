
locals {
  common_tags = {
    Project   = var.project_name
    ManagedBy = "terraform"
  }
}
provider "aws" {
  region = var.region
}

# VPC
module "aws_vpc" {
  source     = "../../../../modules/aws/vpc"
  vpc_name   = var.vpc_name
  cidr_block = var.cidr_block
  tags       = local.common_tags
}

# Public Subnets
module "public_subnet_az1" {
  source                  = "../../../../modules/aws/subnets"
  vpc_id                  = module.aws_vpc.vpc_id
  cidr_block              = "10.0.1.0/24"
  az                      = "eu-north-1a"
  subnet_name             = "public-az1"
  map_public_ip_on_launch = true # ← public

  tags = merge(local.common_tags, {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

module "private_subnet_az1" {
  source                  = "../../../../modules/aws/subnets"
  vpc_id                  = module.aws_vpc.vpc_id
  cidr_block              = "10.0.10.0/24"
  az                      = "eu-north-1a"
  subnet_name             = "private-az1"
  map_public_ip_on_launch = false # ← private 

  tags = merge(local.common_tags, {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

module "public_subnet_az2" {
  source                  = "../../../../modules/aws/subnets"
  vpc_id                  = module.aws_vpc.vpc_id
  cidr_block              = "10.0.2.0/24"
  az                      = "eu-north-1b"
  subnet_name             = "public-az2"
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

module "private_subnet_az2" {
  source                  = "../../../../modules/aws/subnets"
  vpc_id                  = module.aws_vpc.vpc_id
  cidr_block              = "10.0.11.0/24"
  az                      = "eu-north-1b"
  subnet_name             = "private-az2"
  map_public_ip_on_launch = false
  tags = merge(local.common_tags, {
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  })
}

# Internet Gateway
module "aws_igw" {
  source   = "../../../../modules/aws/igw"
  igw_name = "aws-igw"
  vpc_id   = module.aws_vpc.vpc_id
  tags     = local.common_tags
}

# NAT Gateway
module "aws_nat_gw" {
  source      = "../../../../modules/aws/nat_gw"
  subnet_id   = module.public_subnet_az1.subnet_id
  nat_gw_name = "aws-nat-gw"
  igw_id      = module.aws_igw.igw_id
  tags        = local.common_tags
}

# Public Route Table
module "public_rt" {
  source  = "../../../../modules/aws/routetable"
  vpc_id  = module.aws_vpc.vpc_id
  rt_name = "aws-public-rt"
  type    = "public"
  igw_id  = module.aws_igw.igw_id
  tags    = local.common_tags
}

# Private Route Table
module "private_rt" {
  source         = "../../../../modules/aws/routetable"
  vpc_id         = module.aws_vpc.vpc_id
  rt_name        = "aws-private-rt"
  type           = "private"
  nat_gateway_id = module.aws_nat_gw.nat_gw_id
  tags           = local.common_tags
}

# Associate public subnets to public RT
resource "aws_route_table_association" "public_az1" {
  subnet_id      = module.public_subnet_az1.subnet_id
  route_table_id = module.public_rt.rt_id
}
resource "aws_route_table_association" "public_az2" {
  subnet_id      = module.public_subnet_az2.subnet_id
  route_table_id = module.public_rt.rt_id
}

# Associate private subnets to private RT
resource "aws_route_table_association" "private_az1" {
  subnet_id      = module.private_subnet_az1.subnet_id
  route_table_id = module.private_rt.rt_id
}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = module.private_subnet_az2.subnet_id
  route_table_id = module.private_rt.rt_id
}
