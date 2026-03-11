output "vpc_id" {
  description = "VPC ID"
  value       = module.aws_vpc.vpc_id
}

output "public_subnet_az1_id" {
  value = module.public_subnet_az1.subnet_id
}

output "public_subnet_az2_id" {
  value = module.public_subnet_az2.subnet_id
}

output "private_subnet_az1_id" {
  value = module.private_subnet_az1.subnet_id
}

output "private_subnet_az2_id" {
  value = module.private_subnet_az2.subnet_id
}