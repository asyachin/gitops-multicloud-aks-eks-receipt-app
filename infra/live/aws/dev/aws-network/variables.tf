variable "project_name" {
  description = "Project name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "cluster_name" {
  description = "The name of the cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}
variable "prefix" {
  description = "Resource name prefix"
  type        = string
}
variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}