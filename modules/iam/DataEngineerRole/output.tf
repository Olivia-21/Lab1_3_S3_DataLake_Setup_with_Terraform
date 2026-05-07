output "role_name" {
  description = "Name of the DataEngineer IAM Role"
  value = aws_iam_role.data_engineer.name
}

output "role_arn" {
  description = "ARN of the DataEnginner IAM role"
  value = aws_iam_role.data_engineer.arn
}