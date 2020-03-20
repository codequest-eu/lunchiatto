output "create_arn" {
  value = var.create ? aws_lambda_function.create[0].arn : ""
}

output "drop_arn" {
  value = var.create ? aws_lambda_function.drop[0].arn : ""
}

output "security_group_name" {
  value = var.create ? aws_security_group.lambda_2[0].name : ""
}

output "security_group_id" {
  value = var.create ? aws_security_group.lambda_2[0].id : ""
}
