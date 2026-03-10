resource "aws_route_table" "main" {
  vpc_id = var.vpc_id


    dynamic "route" {
    for_each = var.type == "public" ? [1] : []
    content {
        cidr_block = var.cidr_block
        gateway_id = var.igw_id
    }
    }

    dynamic "route" {
    for_each = var.type == "private" ? [1] : []
    content {
        cidr_block = var.cidr_block
        nat_gateway_id = var.nat_gateway_id
    }
    }

    tags = merge(var.tags, {
        Name = var.rt_name
    })
}
