output "igw_id" {
  value = aws_internet_gateway.igw.id
}
output "igw_name" {
  value = aws_internet_gateway.igw.tags["Name"]
}