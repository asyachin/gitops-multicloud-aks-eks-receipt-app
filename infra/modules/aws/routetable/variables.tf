variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "rt_name" {
  description = "The name of the route table"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "type" {
  description = "The type of the route table"
  type        = string
  validation {
    condition     = contains(["public", "private"], var.type)
    error_message = "type must be public or private"
  }
}

variable "igw_id" {
  description = "The ID of the Internet Gateway"
  type        = string
  default     = null
}

variable "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  type        = string
  default     = null
}

variable "cidr_block" {
  type    = string
  default = "0.0.0.0/0"
}
