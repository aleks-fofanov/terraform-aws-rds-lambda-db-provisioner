#############################################################
# Locals
#############################################################

locals {
  lambda_zip_archive_path = "${path.module}/packaged/rds-lambda-db-provisioner.zip"

  # Master user password
  master_password_in_ssm_param        = var.db_master_password_ssm_param != null ? true : false
  master_password_ssm_param_ecnrypted = var.db_master_password_ssm_param_kms_key != null ? true : false
  # Replace null with empty string so that the following regexall will work.
  db_master_password_ssm_param      = var.db_master_password_ssm_param == null ? "" : var.db_master_password_ssm_param
  master_password_in_secretsmanager = length(regexall("/aws/reference/secretsmanager/", local.db_master_password_ssm_param)) > 0

  # Provisioned user password
  user_password_in_ssm_param        = var.db_user_password_ssm_param != null ? true : false
  user_password_ssm_param_ecnrypted = var.db_user_password_ssm_param_kms_key != null ? true : false
  # Replace null with empty string so that the following regexall will work.
  db_user_password_ssm_param      = var.db_user_password_ssm_param == null ? "" : var.db_user_password_ssm_param
  user_password_in_secretsmanager = length(regexall("/aws/reference/secretsmanager/", local.db_user_password_ssm_param)) > 0
}

#############################################################
# Datasources
#############################################################

data "aws_partition" "default" {}

data "aws_db_instance" "default" {
  count = var.enabled ? 1 : 0

  db_instance_identifier = var.db_instance_id
}

data "aws_ssm_parameter" "master_password" {
  count = var.enabled && local.master_password_in_ssm_param ? 1 : 0

  name            = var.db_master_password_ssm_param
  with_decryption = false
}

data "aws_secretsmanager_secret" "master_password" {
  count = var.enabled && local.master_password_in_secretsmanager ? 1 : 0

  name = trimprefix(var.db_master_password_ssm_param, "/aws/reference/secretsmanager/")
}

data "aws_kms_key" "master_password" {
  count = var.enabled && local.master_password_in_ssm_param && local.master_password_ssm_param_ecnrypted ? 1 : 0

  key_id = var.db_master_password_ssm_param_kms_key
}

data "aws_ssm_parameter" "user_password" {
  count = var.enabled && local.user_password_in_ssm_param ? 1 : 0

  name            = var.db_user_password_ssm_param
  with_decryption = false
}

data "aws_secretsmanager_secret" "user_password" {
  count = var.enabled && local.user_password_in_secretsmanager ? 1 : 0

  name = trimprefix(var.db_user_password_ssm_param, "/aws/reference/secretsmanager/")
}

data "aws_kms_key" "user_password" {
  count = var.enabled && local.user_password_in_ssm_param && local.user_password_ssm_param_ecnrypted ? 1 : 0

  key_id = var.db_user_password_ssm_param_kms_key
}

data "aws_kms_key" "lambda" {
  count = var.enabled && var.kms_key != null ? 1 : 0

  key_id = var.kms_key
}

#############################################################
# Label
#############################################################

module "default_label" {
  enabled = var.enabled

  source  = "cloudposse/label/null"
  version = "0.24.1"

  attributes = compact(concat(var.attributes, ["db", "provisioner"]))
  delimiter  = var.delimiter
  name       = var.name
  namespace  = var.namespace
  stage      = var.stage
  tags       = var.tags
}

#############################################################
# Lambda Function
#############################################################

resource "aws_lambda_function" "default" {
  count = var.enabled ? 1 : 0

  depends_on = [
    aws_cloudwatch_log_group.lambda
  ]

  function_name = module.default_label.id
  description   = "Provisions database [${var.db_name}] in RDS Instance [${var.db_instance_id}]"

  filename         = local.lambda_zip_archive_path
  source_code_hash = filebase64sha256(local.lambda_zip_archive_path)

  role        = join("", aws_iam_role.lambda.*.arn)
  handler     = "main.lambda_handler"
  runtime     = "python3.8"
  timeout     = var.timeout
  memory_size = var.memory
  kms_key_arn = var.kms_key

  vpc_config {
    subnet_ids         = var.vpc_config.subnet_ids
    security_group_ids = compact(concat(var.vpc_config.security_group_ids, [join("", aws_security_group.default.*.id)]))
  }

  environment {
    variables = {
      DB_INSTANCE_ID                    = var.db_instance_id
      DB_MASTER_PASSWORD                = var.db_master_password
      DB_MASTER_PASSWORD_SSM_PARAM      = var.db_master_password_ssm_param
      PROVISION_DB_NAME                 = var.db_name
      PROVISION_USER                    = var.db_user
      PROVISION_USER_PASSWORD           = var.db_user_password
      PROVISION_USER_PASSWORD_SSM_PARAM = var.db_user_password_ssm_param
    }
  }

  tags = module.default_label.tags
}

resource "aws_lambda_alias" "default" {
  count = var.enabled ? 1 : 0

  name             = "default"
  description      = "Use latest version as default"
  function_name    = join("", aws_lambda_function.default.*.function_name)
  function_version = "$LATEST"
}

# tflint-ignore: terraform_unused_declarations
data "aws_lambda_invocation" "default" {
  count = var.enabled && var.invoke ? 1 : 0

  depends_on = [
    aws_iam_role_policy_attachment.default_permissions,
    aws_iam_role_policy_attachment.basic_execution,
    aws_iam_role_policy_attachment.vpc_access,
    aws_security_group_rule.egress_from_lambda_to_db_instance,
    aws_security_group_rule.ingress_to_db_instance_from_lambda,
    aws_security_group_rule.egress_blocks,
  ]

  function_name = join("", aws_lambda_function.default.*.function_name)
  input         = ""
}

#############################################################
# Security Groups
#############################################################

resource "aws_security_group" "default" {
  count = var.enabled ? 1 : 0

  name        = module.default_label.id
  description = "Controls access of Lambda DB Provisioner function [${module.default_label.id}] to VPC resources"
  vpc_id      = var.vpc_config.vpc_id

  tags = module.default_label.tags
}

resource "aws_security_group_rule" "egress_from_lambda_to_db_instance" {
  count = var.enabled ? 1 : 0

  description              = "Allow outbound traffic from Lambda to DB Instance"
  type                     = "egress"
  from_port                = join("", data.aws_db_instance.default.*.port)
  to_port                  = join("", data.aws_db_instance.default.*.port)
  protocol                 = "tcp"
  source_security_group_id = var.db_instance_security_group_id
  security_group_id        = join("", aws_security_group.default.*.id)
}

resource "aws_security_group_rule" "ingress_to_db_instance_from_lambda" {
  count = var.enabled ? 1 : 0

  description              = "Allow inbound traffic to DB Instance from Lambda"
  type                     = "ingress"
  from_port                = join("", data.aws_db_instance.default.*.port)
  to_port                  = join("", data.aws_db_instance.default.*.port)
  protocol                 = "tcp"
  source_security_group_id = join("", aws_security_group.default.*.id)
  security_group_id        = var.db_instance_security_group_id
}

resource "aws_security_group_rule" "egress_blocks" {
  count = (var.enabled ? 1 : 0) * (length(var.allowed_egress_cidr_blocks) > 0 ? 1 : 0)

  security_group_id = join("", aws_security_group.default.*.id)

  description = "Allow all egress traffic to specified CIRD blocks"
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = -1
  cidr_blocks = var.allowed_egress_cidr_blocks #tfsec:ignore:AWS007
}

#############################################################
# IAM
#############################################################

data "aws_iam_policy_document" "assume" {
  count = var.enabled ? 1 : 0

  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "default_permissions" {
  count = var.enabled ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "lambda_kms_permissions" {
  count = var.enabled && var.kms_key != null ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [join("", data.aws_kms_key.lambda.*.arn)]
  }
}

data "aws_iam_policy_document" "master_password_ssm_permissions" {
  count = var.enabled && local.master_password_in_ssm_param ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
    ]
    resources = [join("", data.aws_ssm_parameter.master_password.*.arn)]
  }
}

data "aws_iam_policy_document" "master_password_secretsmanager_permissions" {
  count = var.enabled && local.master_password_in_secretsmanager ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [join("", data.aws_secretsmanager_secret.master_password.*.arn)]
  }
}

data "aws_iam_policy_document" "master_password_kms_permissions" {
  count = var.enabled && local.master_password_in_ssm_param && local.master_password_ssm_param_ecnrypted ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [join("", data.aws_kms_key.master_password.*.arn)]
  }
}

data "aws_iam_policy_document" "user_password_ssm_permissions" {
  count = var.enabled && local.user_password_in_ssm_param ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
    ]
    resources = [join("", data.aws_ssm_parameter.user_password.*.arn)]
  }
}

data "aws_iam_policy_document" "user_password_secretsmanager_permissions" {
  count = var.enabled && local.user_password_in_secretsmanager ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [join("", data.aws_secretsmanager_secret.user_password.*.arn)]
  }
}

data "aws_iam_policy_document" "user_password_kms_permissions" {
  count = var.enabled && local.user_password_in_ssm_param && local.user_password_ssm_param_ecnrypted ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [join("", data.aws_kms_key.user_password.*.arn)]
  }
}

module "aggregated_policy" {
  source  = "cloudposse/iam-policy-document-aggregator/aws"
  version = "0.8.0"

  source_documents = compact([
    join("", data.aws_iam_policy_document.default_permissions.*.json),
    join("", data.aws_iam_policy_document.lambda_kms_permissions.*.json),
    join("", data.aws_iam_policy_document.master_password_ssm_permissions.*.json),
    join("", data.aws_iam_policy_document.master_password_kms_permissions.*.json),
    join("", data.aws_iam_policy_document.master_password_secretsmanager_permissions.*.json),
    join("", data.aws_iam_policy_document.user_password_ssm_permissions.*.json),
    join("", data.aws_iam_policy_document.user_password_kms_permissions.*.json),
    join("", data.aws_iam_policy_document.user_password_secretsmanager_permissions.*.json),
  ])
}

resource "aws_iam_role" "lambda" {
  count = var.enabled ? 1 : 0

  name               = module.default_label.id
  assume_role_policy = join("", data.aws_iam_policy_document.assume.*.json)

  tags = module.default_label.tags
}

resource "aws_iam_policy" "default" {
  count = var.enabled ? 1 : 0

  name        = module.default_label.id
  path        = "/"
  description = "IAM policy to control access of Lambda function to AWS resources"

  policy = module.aggregated_policy.result_document
}

resource "aws_iam_role_policy_attachment" "default_permissions" {
  count = var.enabled ? 1 : 0

  role       = join("", aws_iam_role.lambda.*.name)
  policy_arn = join("", aws_iam_policy.default.*.arn)
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  count = var.enabled ? 1 : 0

  role       = join("", aws_iam_role.lambda.*.name)
  policy_arn = "arn:${data.aws_partition.default.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "vpc_access" {
  count = var.enabled ? 1 : 0

  role       = join("", aws_iam_role.lambda.*.name)
  policy_arn = "arn:${data.aws_partition.default.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

#############################################################
# Cloudwatch
#############################################################

resource "aws_cloudwatch_log_group" "lambda" {
  count = var.enabled ? 1 : 0

  name              = "/aws/lambda/${module.default_label.id}"
  retention_in_days = var.logs_retention_days
  kms_key_id        = var.logs_kms_key_id

  tags = module.default_label.tags
}
