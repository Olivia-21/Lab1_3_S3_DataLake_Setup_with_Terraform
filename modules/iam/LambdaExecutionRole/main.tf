#=====================
# PART 1: Lambda Role
#=====================
resource "aws_iam_role" "lambda_role" {
    name = var.role_name
    description = "Execution role for lambda functions to access s3, DynamoDB, Kinesis, CloudWatch Logs and Secrets Manager "

    # Trust policy, who can use this role
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [

            {   Effect = "Allow"
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
                Action = "sts:AssumeRole"
            }
        ]
    })
  
}

#========================
# PART 2: Policies attach
#========================

resource "aws_iam_role_policy_attachment" "lambda_basic_access" {
    role = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "lambda_s3-full-access" {
    role = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
resource "aws_iam_role_policy_attachment" "lambda_dynamodb-full-access" {
    role = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda-kinesis_full_access" {
    role = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
  
}

resource "aws_iam_role_policy_attachment" "secret_manager_read_write" {
  role = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

