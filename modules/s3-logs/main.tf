# =============================================================================
# S3 Logs Module
# =============================================================================
# Creates a dedicated bucket for audit logs.
# Kept intentionally simple — no lifecycle rules, no folder structure,
# no bucket policy needed. Its only job is to receive and store logs.
#
# Receives logs from:
#   - S3 access logging (main data lake bucket)
#   - CloudTrail audit trail
# =============================================================================

locals {
  bucket_name = "data-lake-${var.environment}-logs-${var.account_id}"
}

resource "aws_s3_bucket" "logs" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name        = local.bucket_name
    Environment = var.environment
    Purpose     = "Audit logs - S3 access logs and CloudTrail"
    ManagedBy   = "Terraform"
  }
}

# Block all public access — logs must never be public
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encryption — logs encrypted at rest using AES256
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Versioning — keep previous versions of log files for forensics
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------------------
# Bucket ownership controls
# Required for S3 access logging to work.
# AWS needs permission to write log files into this bucket.
# Without this, access logging silently fails.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Grant S3 logging service permission to write to this bucket
resource "aws_s3_bucket_acl" "logs" {
  bucket     = aws_s3_bucket.logs.id
  acl        = "log-delivery-write"
  depends_on = [aws_s3_bucket_ownership_controls.logs]
}

# -----------------------------------------------------------------------------
# Lifecycle rule — auto-delete old logs to control costs
# Logs are for auditing, not long-term storage
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {
      prefix = ""    # applies to all objects in the bucket
    }

    # Move to cheaper storage after 90 days (logs rarely accessed after this)
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    # Move to Glacier after 1 year
    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    # Delete after 7 years (GDPR compliance — right to be forgotten)
    expiration {
      days = 2555    # 7 years × 365 days
    }
  }
}
