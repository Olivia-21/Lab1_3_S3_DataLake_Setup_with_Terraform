# ============================================
# PART A: Analyst Read Only Role Creation
# ============================================
resource "aws_iam_role" "analyst_role" {
    name = var.role_name
    description = "Read-only for analysts to access Redshift, Athena, QuickSight and S3"

    # Trust policy who can use this role
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
            }

        ]

    })
  
}

# ============================================
# PART B: Attach the 4 policies to the role
# ============================================
resource "aws_iam_role_policy_attachment" "athena_full_acess" {
  role = aws_iam_role.analyst_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
}

resource "aws_iam_role_policy_attachment" "redshift_read_only_access" {
  role = aws_iam_role.analyst_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftReadOnlyAccess"
}


resource "aws_iam_role_policy_attachment" "s3-read-only" {
  role = aws_iam_role.analyst_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# QuickSight access is NOT managed via IAM policies. 
# QuickSight uses its own internal permission system 