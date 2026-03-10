output "vpc_id" {
  value = aws_vpc.main.id
}
output "vpc_name" {
  value = aws_vpc.main.tags["Name"]
}
output "vpc_cidr" {
  description = "The CIDR block for the VPC"
  value = aws_vpc.main.cidr_block
}