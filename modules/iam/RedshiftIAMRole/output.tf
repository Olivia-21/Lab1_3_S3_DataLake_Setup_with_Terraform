output "role_arn" {
  description = "ARN of the RedshiftRole"
  value = aws_iam_role.redshift_role.arn
}