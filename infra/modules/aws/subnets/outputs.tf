output "subnet_id" {
  value = aws_subnet.main.id
}
output "subnet_name" {
  value = aws_subnet.main.tags["Name"]
}
output "subnet_cidr" {
  value = aws_subnet.main.cidr_block
}
output "subnet_arn" {
  value = aws_subnet.main.arn
}

output "availability_zone" {
  value = aws_subnet.main.availability_zone
}

output "vpc_id" {
  value = aws_subnet.main.vpc_id
}

output "map_public_ip_on_launch" {
  value = aws_subnet.main.map_public_ip_on_launch
}