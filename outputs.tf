output "lambda_iam_policy_id" {
  description = "Lambda IAM Policy ID"
  value       = join("", aws_iam_policy.default.*.id)
}

output "lambda_iam_policy_name" {
  description = "Lambda IAM Policy name"
  value       = join("", aws_iam_policy.default.*.name)
}

output "lambda_iam_policy_arn" {
  description = "Lambda IAM Policy ARN"
  value       = join("", aws_iam_policy.default.*.arn)
}

output "lambda_iam_role_id" {
  description = "Lambda IAM Role ID"
  value       = join("", aws_iam_role.lambda.*.id)
}

output "lambda_iam_role_name" {
  description = "Lambda IAM Role name"
  value       = join("", aws_iam_role.lambda.*.name)
}

output "lambda_iam_role_arn" {
  description = "Lambda IAM Role ARN"
  value       = join("", aws_iam_role.lambda.*.arn)
}

output "lambda_function_arn" {
  description = "Lambda Function ARN"
  value       = join("", aws_lambda_function.default.*.arn)
}

output "lambda_function_name" {
  description = "Lambda Function name"
  value       = join("", aws_lambda_function.default.*.function_name)
}

