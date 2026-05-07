# =============================================================================
# S3 Datalake Module — Main Data Lake Bucket
# =============================================================================
# Creates a production-ready S3 data lake with:
#   1. Bucket with unique name (includes account ID)
#   2. Public access blocked
#   3. Encryption (SSE-S3)
#   4. Versioning (recover deleted files)
#   5. Server access logging (who accessed what)
#   6. Folder structure (raw, processed, curated, temp, archive)
#   7. Lifecycle policies (cost optimisation)
#   8. Bucket policy (enforce HTTPS, encryption, role-based access)
# =============================================================================

locals {
  bucket_name = "data-lake-${var.environment}-${var.account_id}"
}

# =============================================================================
# 1. BUCKET
# =============================================================================

resource "aws_s3_bucket" "datalake" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name        = local.bucket_name
    Environment = var.environment
    Purpose     = "DataLake"
    Owner       = "DataEngineering"
    CostCenter  = "Analytics"
    ManagedBy   = "Terraform"
  }
}

# =============================================================================
# 2. BLOCK ALL PUBLIC ACCESS
# Data lake buckets must never be public
# =============================================================================

resource "aws_s3_bucket_public_access_block" "datalake" {
  bucket                  = aws_s3_bucket.datalake.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# 3. ENCRYPTION — SSE-S3
# All objects encrypted at rest. Free, AWS manages the keys.
# Meets GDPR, HIPAA, PCI-DSS requirements.
# =============================================================================

resource "aws_s3_bucket_server_side_encryption_configuration" "datalake" {
  bucket = aws_s3_bucket.datalake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# =============================================================================
# 4. VERSIONING
# Keeps every version of every object.
# If someone deletes or overwrites a file — you can recover it.
# =============================================================================

resource "aws_s3_bucket_versioning" "datalake" {
  bucket = aws_s3_bucket.datalake.id

  versioning_configuration {
    status = "Enabled"
  }
}

# =============================================================================
# 5. SERVER ACCESS LOGGING
# Records every S3 API call (GetObject, PutObject, DeleteObject, etc.)
# Logs written to the dedicated logs bucket (created by s3-logs module).
# Required for compliance audits.
# =============================================================================

resource "aws_s3_bucket_logging" "datalake" {
  bucket        = aws_s3_bucket.datalake.id
  target_bucket = var.logs_bucket_id
  target_prefix = "s3-access-logs/"    # organise logs in their own subfolder
}

# =============================================================================
# 6. FOLDER STRUCTURE
# S3 doesn't have real folders — these are empty objects with / in the key.
# They act as placeholders that appear as folders in the console.
#
# raw/        → immutable source data, never modified
# processed/  → cleaned, validated, transformed data
# curated/    → business-ready, analytics-optimised data
# temp/       → temporary job outputs, auto-deleted after 1 day
# archive/    → long-term storage for compliance
# =============================================================================

resource "aws_s3_object" "folder_raw" {
  bucket  = aws_s3_bucket.datalake.id
  key     = "raw/"
  content = ""

  server_side_encryption = "AES256"
}

resource "aws_s3_object" "folder_processed" {
  bucket  = aws_s3_bucket.datalake.id
  key     = "processed/"
  content = ""

  server_side_encryption = "AES256"
}

resource "aws_s3_object" "folder_curated" {
  bucket  = aws_s3_bucket.datalake.id
  key     = "curated/"
  content = ""

  server_side_encryption = "AES256"
}

resource "aws_s3_object" "folder_temp" {
  bucket  = aws_s3_bucket.datalake.id
  key     = "temp/"
  content = ""

  server_side_encryption = "AES256"
}

resource "aws_s3_object" "folder_archive" {
  bucket  = aws_s3_bucket.datalake.id
  key     = "archive/"
  content = ""

  server_side_encryption = "AES256"
}

# =============================================================================
# 7. LIFECYCLE POLICIES — Cost optimisation
# =============================================================================
# Policy 1: processed/ → Glacier after 90 days, Deep Archive after 180 days
# Policy 2: temp/      → DELETE after 1 day (temporary job outputs)
# Policy 3: archive/   → Glacier after 1 day, Deep Archive after 30 days,
#                         DELETE after 7 years (GDPR compliance)
# =============================================================================

resource "aws_s3_bucket_lifecycle_configuration" "datalake" {
  bucket = aws_s3_bucket.datalake.id

  # ── Rule 1: Archive processed data ────────────────────────────────────────
  rule {
    id     = "archive-processed-data-after-90-days"
    status = "Enabled"

    filter {
      prefix = "processed/"
    }

    transition {
      days          = 91
      storage_class = "GLACIER_IR"    # Glacier Instant Retrieval — $0.004/GB
    }

    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"  # Deep Archive — $0.00099/GB
    }
  }

  # ── Rule 2: Delete temp data after 1 day ──────────────────────────────────
  rule {
    id     = "delete-temp-data-after-1-day"
    status = "Enabled"

    filter {
      prefix = "temp/"
    }

    expiration {
      days = 1    # temp files are gone after 1 day automatically
    }
  }

  # ── Rule 3: Archive then delete after 7 years ─────────────────────────────
  rule {
    id     = "archive-and-delete-after-7-years"
    status = "Enabled"

    filter {
      prefix = "archive/"
    }

    transition {
      days          = 1
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = 91
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 2555    # 7 years × 365 = GDPR right to be forgotten
    }
  }
}

# =============================================================================
# 8. BUCKET POLICY
# =============================================================================
# Statement 1 — EnforceSSLOnly:
#   DENY all traffic that isn't HTTPS.
#   Prevents data interception in transit.
#
# Statement 2 — DenyUnencryptedObjectUploads:
#   DENY uploads without AES256 encryption header.
#   Even if someone forgets to encrypt, policy blocks them.
#
# Statement 3 — AllowDataEngineerRole:
#   ALLOW read/write/delete/list for data engineers.
#
# Statement 4 — AllowGlueServiceRole:
#   ALLOW read/write/list for Glue ETL jobs.
#
# Statement 5 — AllowRedshiftRole:
#   ALLOW read/list only for Redshift COPY commands.
# =============================================================================

resource "aws_s3_bucket_policy" "datalake" {
  bucket = aws_s3_bucket.datalake.id

  # depends_on ensures public access block is applied before bucket policy
  # Without this, Terraform sometimes tries to apply the policy first
  # which can fail if the block isn't in place yet
  depends_on = [aws_s3_bucket_public_access_block.datalake]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceSSLOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::${local.bucket_name}",
          "arn:aws:s3:::${local.bucket_name}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${local.bucket_name}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "AES256"
          }
        }
      },
      {
        Sid    = "AllowDataEngineerRole"
        Effect = "Allow"
        Principal = {
          AWS = var.data_engineer_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.bucket_name}",
          "arn:aws:s3:::${local.bucket_name}/*"
        ]
      },
      {
        Sid    = "AllowGlueServiceRole"
        Effect = "Allow"
        Principal = {
          AWS = var.glue_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.bucket_name}",
          "arn:aws:s3:::${local.bucket_name}/*"
        ]
      },
      {
        Sid    = "AllowRedshiftRole"
        Effect = "Allow"
        Principal = {
          AWS = var.redshift_role_arn
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.bucket_name}",
          "arn:aws:s3:::${local.bucket_name}/*"
        ]
      }
    ]
  })
}
