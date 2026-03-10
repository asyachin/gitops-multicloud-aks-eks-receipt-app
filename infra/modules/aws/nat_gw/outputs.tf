output "nat_gw_id" {
  value = aws_nat_gateway.main.id
}

output "nat_gw_name" {
  value = aws_nat_gateway.main.tags["Name"]
}

output "eip_id" {
  value = aws_eip.main.id
}

output "eip_public_ip" {
  value = aws_eip.main.public_ip
}
