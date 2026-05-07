# ==========================
# PART A: The role itself
#===========================

resource "aws_iam_role" "data_engineer" {
    name = var.role_name
    description = "Role for data engineers to access s3, Glue, Redshift, EMR, Kinesis, Lambda, and CloudWatch"
    
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
# PART B: Attach the 7 policies to the role
# ============================================

resource "aws_iam_role_policy_attachment" "s3_full_access" {
    role = aws_iam_role.data_engineer.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  
}

resource "aws_iam_role_policy_attachment" "glue_full_access" {
    role = aws_iam_role.data_engineer.name
    policy_arn = "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
  
}

resource "aws_iam_role_policy_attachment" "redshift_full_access" {
    role = aws_iam_role.data_engineer.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
  
}

resource "aws_iam_role_policy_attachment" "emr_full_access" {
    role = aws_iam_role.data_engineer.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEMRFullAccessPolicy_v2"  
}

resource "aws_iam_role_policy_attachment" "kinesis_full_access" {
    role = aws_iam_role.data_engineer.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
  
}

resource "aws_iam_role_policy_attachment" "lambda_full_access" {
    role = aws_iam_role.data_engineer.name
    policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_full_access" {
    role = aws_iam_role.data_engineer.name
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

