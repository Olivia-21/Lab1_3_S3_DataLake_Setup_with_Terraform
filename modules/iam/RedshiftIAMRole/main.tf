#=====================
# PART 1: Redshift Role
#=====================
resource "aws_iam_role" "redshift_role" {
    name = var.role_name
    description = "Service role for Redshift to read/write to s3 and write cloudWatch Logs "

    # Trust policy, who can use this role
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [

            {   Effect = "Allow"
                Principal = {
                    Service = "redshift.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        ]
    })
  
}

#========================
# PART 2: Policies attach
#========================


resource "aws_iam_role_policy_attachment" "redshift_s3-full-access" {
    role = aws_iam_role.redshift_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "redshift_cloudwatch_full_access" {
    role = aws_iam_role.redshift_role.name
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  
}

