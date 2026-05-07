# =============================================================================
# S3 Logs Module — Input Variables
# =============================================================================
# Simple bucket for storing:
#   - S3 access logs from the main data lake bucket
#   - CloudTrail audit logs
# Must be created BEFORE s3-datalake module since main bucket
# references this bucket's name for access logging configuration.
# =============================================================================

variable "environment" {
  description = "Deployment environment (dev, prod). Used in bucket naming."
  type        = string
}

variable "account_id" {
  description = <<-EOT
    AWS account ID. Used to make bucket name globally unique.
    Pass in: data.aws_caller_identity.current.account_id
    Never hardcode this value.
  EOT
  type        = string
}

variable "region" {
  description = "AWS region where the bucket will be created."
  type        = string
  default     = "us-east-1"
}

variable "force_destroy" {
  description = "Allow bucket deletion even if it contains logs. Set true for dev only."
  type        = bool
  default     = false
}
