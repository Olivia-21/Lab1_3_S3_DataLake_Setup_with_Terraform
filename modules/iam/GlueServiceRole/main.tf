# ============================================
# PART A: Glue Role Creation
# ============================================
resource "aws_iam_role" "glue_role" {
    name = var.role_name
    description = "Glue role to access s3, secret manager, cloudwatch and perform glue operation"

    # Trust policy who can use this role
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
            Effect = "Allow"
            Principal = {
                Service = "glue.amazonaws.com"
            }
            Action = "sts:AssumeRole"
            }

        ]

    })
  
}

# ============================================
# PART B: Attach the 4 policies to the role
# ============================================
resource "aws_iam_role_policy_attachment" "aws_glue_basic_service" {
  role = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_full_access" {
    role = aws_iam_role.glue_role.name
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  
}

resource "aws_iam_role_policy_attachment" "secret_manager_read_write" {
  role = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
