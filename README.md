# Lab 1.3 — S3 Data Lake Foundation

## Overview
This module provisions a production-ready S3 data lake with full data governance,
security, compliance, and cost optimisation. It creates two buckets — a main data
lake bucket and a dedicated logs bucket — following the separation of concerns principle.

---

## Architecture

```
Infrastructure/
└── modules/
    ├── s3-logs/              ← created first (main bucket depends on it)
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── s3-datalake/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### Bucket Structure

```
data-lake-prod-821528308689/        ← main data lake bucket
│
├── raw/                            ← immutable source data
│   └── (data lands here from source systems)
│
├── processed/                      ← cleaned, validated, transformed
│   └── (Glue ETL jobs write here)
│
├── curated/                        ← business-ready, analytics-optimised
│   └── (BI tools and dashboards read from here)
│
├── temp/                           ← temporary job outputs
│   └── (auto-deleted after 1 day)
│
└── archive/                        ← long-term compliance storage
    └── (moved to Glacier immediately)

data-lake-prod-logs-821528308689/   ← dedicated logs bucket
│
├── s3-access-logs/                 ← S3 access logs (who accessed data)
│   └── 2026-05-06-09-33-42-...
│
└── AWSLogs/                        ← CloudTrail audit logs (who changed infrastructure)
    └── 821528308689/
        └── CloudTrail/
            └── us-east-1/
                └── 2026/05/06/
```

---

## Data Flow

```
Source Systems
      ↓
   raw/          ← never modified, source of truth
      ↓
   Glue ETL job
      ↓
   processed/    ← cleaned, validated
      ↓
   Glue ETL job
      ↓
   curated/      ← analytics-ready, partitioned
      ↓
   Athena / Redshift / QuickSight
      ↓
   Dashboards & Reports
```

---

## Resources Created

### s3-logs Module

| Resource | Purpose |
|----------|---------|
| `aws_s3_bucket` | Dedicated logs bucket |
| `aws_s3_bucket_public_access_block` | Block all public access |
| `aws_s3_bucket_server_side_encryption_configuration` | SSE-S3 encryption at rest |
| `aws_s3_bucket_versioning` | Keep previous log versions for forensics |
| `aws_s3_bucket_ownership_controls` | Required for S3 access logging to work |
| `aws_s3_bucket_acl` | Grant AWS logging service write permission |
| `aws_s3_bucket_lifecycle_configuration` | Auto-expire old logs after 7 years |

> **Why a separate bucket for logs?**
> Mixing logs with data creates confusion, lifecycle conflicts, and compliance issues.
> Separate bucket = separate purpose, separate access controls, separate retention.

---

### s3-datalake Module

| Resource | Purpose |
|----------|---------|
| `aws_s3_bucket` | Main data lake bucket |
| `aws_s3_bucket_public_access_block` | Block all public access |
| `aws_s3_bucket_server_side_encryption_configuration` | SSE-S3 encryption at rest |
| `aws_s3_bucket_versioning` | Recover deleted/overwritten files |
| `aws_s3_bucket_logging` | Write access logs to s3-logs bucket |
| `aws_s3_object` × 5 | Create folder placeholders (raw, processed, curated, temp, archive) |
| `aws_s3_bucket_lifecycle_configuration` | Auto-move data to cheaper storage tiers |
| `aws_s3_bucket_policy` | Enforce HTTPS, encryption, and role-based access |

---

## Security Configuration

### Encryption — SSE-S3
```
All objects encrypted at rest using AES-256.
AWS manages the encryption keys at no extra cost.
Meets: GDPR, HIPAA (basic), PCI-DSS requirements.

How it works:
  Upload file → S3 encrypts with AES-256 → stores encrypted
  Download file → S3 decrypts automatically → returns plain text
  Stolen hard drive → unreadable gibberish without the key
```

### Bucket Policy Statements

| Statement | Effect | Purpose |
|-----------|--------|---------|
| EnforceSSLOnly | Deny | Block all non-HTTPS connections |
| DenyUnencryptedObjectUploads | Deny | Block uploads without AES256 header |
| AllowDataEngineerRole | Allow | Full read/write/delete/list access |
| AllowGlueServiceRole | Allow | Read/write/list (no delete) |
| AllowRedshiftRole | Allow | Read/list only (for COPY commands) |

> **Why deny unencrypted uploads if default encryption is enabled?**
> Default encryption encrypts after upload. The bucket policy blocks the upload
> entirely if no encryption header is present — even if the uploader has valid
> IAM permissions. Nobody can accidentally bypass encryption.

---

## Data Zone Policies

| Zone | Mutation | Retention | Storage Class | Purpose |
|------|----------|-----------|---------------|---------|
| raw/ | Never | Forever | Standard | Immutable source of truth |
| processed/ | Occasionally | 7 years | Standard → Glacier (90d) | Cleaned data |
| curated/ | Never (read-only) | 2-3 years | Standard | Analytics-ready |
| temp/ | Constantly | 1 day | Standard → DELETE | Scratch space |
| archive/ | Never | 7 years | Glacier (day 1) → Deep Archive (day 30) | Compliance |

---

## Lifecycle Policies

### Rule 1 — Archive Processed Data
```
processed/ objects:
  Day 0:   S3 Standard       $0.023/GB  (actively used)
  Day 90:  Glacier IR        $0.004/GB  (rarely accessed, save 83%)
  Day 180: Deep Archive      $0.00099/GB (never accessed, save 96%)

Cost saving example:
  1TB for 7 years without lifecycle: $1,932
  1TB for 7 years with lifecycle:    $348
  Saving: $1,584 (82% cheaper)
```

### Rule 2 — Delete Temp Data
```
temp/ objects → DELETE after 1 day

Why: Spark jobs create gigabytes of temp files automatically.
     If not deleted, costs accumulate silently.
     Nobody ever needs yesterday's temp files.
```

### Rule 3 — Archive and Delete After 7 Years
```
archive/ objects:
  Day 1:    Glacier IR       (compliance hold begins)
  Day 30:   Deep Archive     (cheapest long-term storage)
  Day 2555: DELETE           (7 years = GDPR right to be forgotten)

Why 7 years: Legal requirement in most jurisdictions for financial/personal data.
```

---

## Audit and Compliance

### S3 Access Logging
```
Records every S3 API call:
  WHO accessed (IAM user/role, IP address)
  WHAT they accessed (bucket, object key)
  WHEN they accessed (timestamp)
  HOW (GetObject, PutObject, DeleteObject, ListBucket)
  RESULT (success or failure)

Use cases:
  Compliance audit: "Prove who accessed health records last quarter"
  Forensics:        "What did the attacker download?"
  Debugging:        "Why is this analyst getting permission denied?"
```

### CloudTrail
```
Records every AWS API call (not just S3):
  Who created/deleted/modified infrastructure
  Who changed the bucket policy
  Who modified IAM roles
  Exact timestamp and IP address

Difference from access logs:
  Access logs → what data was accessed
  CloudTrail  → what infrastructure was changed
```

---

## Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `environment` | Yes | — | Deployment environment |
| `account_id` | Yes | — | AWS account ID (use data.aws_caller_identity) |
| `region` | No | us-east-1 | AWS region |
| `force_destroy` | No | false | Allow deletion with objects (dev only) |
| `logs_bucket_id` | Yes | — | Name of logs bucket (from s3-logs module) |
| `data_engineer_role_arn` | Yes | — | DataEngineerRole ARN (from Lab 1.1) |
| `glue_role_arn` | Yes | — | GlueServiceRole ARN (from Lab 1.1) |
| `redshift_role_arn` | Yes | — | RedshiftIAMRole ARN (from Lab 1.1) |

---

## Outputs

| Output | Description |
|--------|-------------|
| `bucket_id` | Main bucket name |
| `bucket_arn` | Main bucket ARN — used by CloudTrail and IAM |
| `bucket_domain_name` | Domain name for S3 URLs |

---

## Usage

```hcl
# Always create logs bucket first
module "data_lake_logs" {
  source        = "../modules/s3-logs"
  environment   = "dev"
  account_id    = data.aws_caller_identity.current.account_id
  force_destroy = true    # dev only
}

# Main bucket receives logs bucket name as input
module "data_lake_main" {
  source        = "../modules/s3-datalake"
  environment   = "dev"
  account_id    = data.aws_caller_identity.current.account_id
  force_destroy = true    # dev only

  logs_bucket_id         = module.data_lake_logs.bucket_id
  data_engineer_role_arn = module.data_engineer_role.role_arn
  glue_role_arn          = module.glue_role.role_arn
  redshift_role_arn      = module.redshift_role.role_arn
}
```

---

## Dependencies

```
Lab 1.1 IAM module must be applied first:
  module.data_engineer_role → provides data_engineer_role_arn
  module.glue_role          → provides glue_role_arn
  module.redshift_role      → provides redshift_role_arn

s3-logs module must be applied before s3-datalake:
  module.data_lake_logs → provides logs_bucket_id
```

---

## Prerequisites
- Completed Lab 1.1 (IAM roles)
- Completed Lab 1.2 (VPC — optional for S3 but required for future labs)
- AWS account with admin or PowerUser access
- Terraform >= 1.0

## Deployment

```bash
cd Infrastructure/terraform
terraform init
terraform plan
terraform apply
```

---

## Cost Breakdown

| Resource | Cost |
|----------|------|
| S3 Standard storage | $0.023/GB/month |
| S3 Glacier IR | $0.004/GB/month |
| S3 Deep Archive | $0.00099/GB/month |
| S3 GET requests | $0.0004 per 1,000 |
| S3 PUT requests | $0.005 per 1,000 |
| Access logging | Minimal (log files are small) |
| CloudTrail management events | Free (first trail per region) |
| Lifecycle transitions | Free (automatic) |

> **Estimated cost for lab:** ~$0.00 (test data is < 1KB, deleted after lab)
> **Estimated cost for 1TB production lake:** ~$23/month (Standard) or ~$1/month (Deep Archive)

---

## Compliance Coverage

| Regulation | Requirement | How We Meet It |
|------------|------------|----------------|
| GDPR | Encrypt personal data | SSE-S3 on all objects |
| GDPR | Right to be forgotten | Lifecycle deletes after 7 years |
| GDPR | Audit trail | CloudTrail + access logging |
| HIPAA | Encrypt health data | SSE-S3 on all objects |
| HIPAA | Access audit trail | CloudTrail + access logging |
| PCI-DSS | Encrypt payment data | SSE-S3 on all objects |
| SOC2 | Access controls | Bucket policy + IAM roles |
