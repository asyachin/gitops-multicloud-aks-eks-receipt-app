# =============================================================================
# BOOTSTRAP MODULE VARIABLES
# =============================================================================

# =============================================================================
# Required Variables
# =============================================================================

variable "region" {
  description = "AWS region"
  type        = string
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (development, staging, production)"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID for bucket policy"
  type        = string
}

