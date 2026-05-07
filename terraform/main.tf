provider "aws" {
    region = var.aws_region

    default_tags {
      tags = {
        lab = "CDEM1"
        ManagedBy = "Terraform"
      }
    }
}

# Pulls current AWS account ID dynamically
# Required for s3-logs and s3-datalake modules
data "aws_caller_identity" "current" {}

# =============================================================================
# Lab 1.1 — IAM Roles
# =============================================================================
module "data_engineer_role" {
  source = "../modules/iam/DataEngineerRole"
  role_name = "DataEngineerRole"
  Environment = "dev"
}

module "glue_service_role" {
  source = "../modules/iam/GlueServiceRole"
  role_name = "GlueServiceRole"
}

module "lambda_service_role" {
  source = "../modules/iam/LambdaExecutionRole"
  role_name = "LambdaExecutionRole"
}

module "redshift_role" {
  source = "../modules/iam/RedshiftIAMRole"
  role_name = "RedshiftIAMRole"
}

module "analyst_role" {
  source = "../modules/iam/AnalystReadOnlyRole"
  role_name = "AnalystReadOnlyRole"
}

# =============================================================================
# Lab 1.2 — Networking
# =============================================================================

module "networking" {
  source      = "../modules/networking"
  environment = "dev"
  region      = "us-east-1"

  # NAT Gateway off by default — costs $0.32/hour (~$232/month)
  # Set to true only when private subnets need outbound internet access
  enable_nat_gateway = false
}

# =============================================================================
# Lab 1.3 — S3 Data Lake
# =============================================================================

# Logs bucket MUST be created first — main bucket references its name
module "data_lake_logs" {
  source      = "../modules/s3-logs"
  environment = "dev"
  account_id  = data.aws_caller_identity.current.account_id
  region      = "us-east-1"
  force_destroy = true    # dev only
}

# Main data lake bucket — receives logs bucket name as input
module "data_lake_main" {
  source        = "../modules/s3-datalake"
  environment   = "dev"
  account_id    = data.aws_caller_identity.current.account_id
  region        = "us-east-1"
  force_destroy = true    # dev only

  # Logs bucket — created above, passed in here
  logs_bucket_id = module.data_lake_logs.bucket_id

  # IAM role ARNs from Lab 1.1 — passed into bucket policy
  data_engineer_role_arn = module.data_engineer_role.role_arn
  glue_role_arn          = module.glue_service_role.role_arn
  redshift_role_arn      = module.redshift_role.role_arn
}


