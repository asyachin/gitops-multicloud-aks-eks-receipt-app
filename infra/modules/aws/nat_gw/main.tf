resource "aws_eip" "main" {
  domain = "vpc"

  tags = {
    Name = "${var.nat_gw_name}-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.main.id
  subnet_id     = var.subnet_id

  tags = merge(var.tags, {
    Name = var.nat_gw_name
  })

}