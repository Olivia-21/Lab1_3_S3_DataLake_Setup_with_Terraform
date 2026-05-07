output "glue_name" {
  description = "value"
  value = aws_iam_role.glue_role.name
}

output "role_arn" {
  description = "ARN of the glue role"
  value = aws_iam_role.glue_role.arn 
}