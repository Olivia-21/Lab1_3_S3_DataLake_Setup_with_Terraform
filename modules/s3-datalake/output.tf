# =============================================================================
# S3 Datalake Module — Outputs
# =============================================================================

output "bucket_id" {
  description = "Name of the data lake S3 bucket"
  value       = aws_s3_bucket.datalake.id
}

output "bucket_arn" {
  description = "ARN of the data lake S3 bucket — used by CloudTrail and IAM policies"
  value       = aws_s3_bucket.datalake.arn
}

output "bucket_domain_name" {
  description = "Domain name of the bucket — used for constructing S3 URLs"
  value       = aws_s3_bucket.datalake.bucket_domain_name
}
