variable "subnet_id" {
    description = "The ID of the subnet to associate with the NAT gateway"
    type = string
}

variable "nat_gw_name" {
    description = "The name of the NAT gateway"
    type = string
}

variable "igw_id" {
    description = "The ID of the Internet Gateway"
    type = string
}

variable "tags" {
    description = "Common tags"
    type = map(string)
    default = {}
}
