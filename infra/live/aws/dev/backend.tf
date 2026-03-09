
terraform {
  backend "s3" {
    bucket  = var.bucket
    key     = var.key
    region  = var.region
    encrypt = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
  }
}