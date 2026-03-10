# Source: 
# https://registry.terraform.io/providers/-/aws/6.5.0/docs/resources/subnet


resource "aws_subnet" "main" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.cidr_block
  availability_zone       = var.az
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(var.tags, {
    Name = var.subnet_name
  })
}