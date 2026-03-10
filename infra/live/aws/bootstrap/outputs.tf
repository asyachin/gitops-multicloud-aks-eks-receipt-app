# =============================================================================
# BOOTSTRAP MODULE OUTPUTS
# =============================================================================

output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "s3_bucket_region" {
  description = "Region of the S3 bucket"
  value       = var.region
}


output "backend_config" {
  description = "Backend configuration for other modules"
  value = {
    bucket  = aws_s3_bucket.terraform_state.id
    region  = var.region
    encrypt = true
  }
}