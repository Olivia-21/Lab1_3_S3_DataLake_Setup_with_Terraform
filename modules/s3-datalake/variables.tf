# =============================================================================
# S3 Datalake Module — Input Variables
# =============================================================================

variable "environment" {
  description = "Deployment environment (dev, prod). Used in bucket naming."
  type        = string
}

variable "account_id" {
  description = <<-EOT
    AWS account ID. Makes bucket name globally unique.
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
  description = "Allow bucket deletion even if it contains objects. Set true for dev only."
  type        = bool
  default     = false
}

variable "logs_bucket_id" {
  description = <<-EOT
    Name of the logs bucket to receive S3 access logs.
    Comes from: module.data_lake_logs.bucket_id
    Must be created before this module runs.
  EOT
  type        = string
}

# -----------------------------------------------------------------------------
# IAM role ARNs for bucket policy
# These come from the IAM modules created in Lab 1.1
# -----------------------------------------------------------------------------
variable "data_engineer_role_arn" {
  description = "ARN of DataEngineerRole — granted read/write/delete access"
  type        = string
}

variable "glue_role_arn" {
  description = "ARN of GlueServiceRole — granted read/write access"
  type        = string
}

variable "redshift_role_arn" {
  description = "ARN of RedshiftIAMRole — granted read-only access"
  type        = string
}
