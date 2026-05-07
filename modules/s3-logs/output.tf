# =============================================================================
# S3 Logs Module — Outputs
# =============================================================================
# bucket_id and bucket_arn are consumed by:
#   - s3-datalake module (for server access logging target)
#   - CloudTrail module (for audit trail storage)
# =============================================================================

output "bucket_id" {
  description = "Name of the logs S3 bucket — used as access logging target"
  value       = aws_s3_bucket.logs.id
}

output "bucket_arn" {
  description = "ARN of the logs S3 bucket — used by CloudTrail"
  value       = aws_s3_bucket.logs.arn
}
