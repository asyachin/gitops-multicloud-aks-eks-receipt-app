output "rt_id" {
  value = aws_route_table.main.id
}

output "rt_name" {
  value = aws_route_table.main.tags["Name"]
}
