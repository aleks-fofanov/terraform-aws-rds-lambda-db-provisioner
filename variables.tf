variable "namespace" {
  type        = string
  description = "Namespace (e.g. `cp` or `cloudposse`)"
  default     = ""
}

variable "stage" {
  type        = string
  description = "Stage (e.g. `prod`, `dev`, `staging`)"
  default     = ""
}

variable "name" {
  type        = string
  default     = "rds"
  description = "Solution name, e.g. 'app' or 'jenkins'"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `namespace`, `name`, `stage` and `attributes`"
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes, e.g. `1`"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map(`BusinessUnit`,`XYZ`)"
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Defines whether this module should create resources"
}

variable "memory" {
  type        = number
  default     = 256
  description = "Amount of memory in MB your Lambda Function can use at runtime"
}

variable "timeout" {
  type        = number
  default     = 30
  description = "The amount of time your Lambda Function has to run in seconds"
}

variable "vpc_config" {
  type = object({
    vpc_id             = string
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  description = "VPC configuration for Lambda function"
}

variable "kms_key" {
  type        = string
  default     = null
  description = "KMS key identifier. Accepts the same format as KMS key data source (https://www.terraform.io/docs/providers/aws/d/kms_key.html). If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key."
}

variable "invoke" {
  type        = bool
  default     = true
  description = "Defines whether lambda function should be invoked immediately after provisioning"
}

variable "logs_retention_days" {
  type        = number
  description = "Lambda function logs retentions in days"
  default     = null
}

variable "logs_kms_key_id" {
  type        = string
  description = "KMS Key Id for Lambda function logs ecnryption"
  default     = null
}

variable "db_instance_id" {
  type        = string
  description = "DB Instance Identifier"
}

variable "db_master_password_ssm_param" {
  type        = string
  default     = null
  description = "Name of SSM Parameter that stores password for master user. This param takes precedence other `db_master_password`"
}

variable "db_master_password_ssm_param_kms_key" {
  type        = string
  default     = null
  description = "Identifier of KMS key used for encryption of SSM Parameter that stores password for master user"
}

variable "db_master_password" {
  type        = string
  default     = null
  description = "DB Instance master password. The usage of this parameter is discouraged. Consider putting db password in SSM Parameter Store and passing its ARN to the module via `db_master_password_ssm_parameter_arn` parameter"
}

variable "db_instance_security_group_id" {
  type        = string
  description = "DB instance security group to add rules to. Rules will allow communication between Lambda and DB instance"
  default     = null
}

variable "db_name" {
  type        = string
  description = "Database name that should be created"
}

variable "db_user" {
  type        = string
  description = "Name of user that should be created and own (has all permission to) the provisioned database. If left empty, no user will be created"
  default     = null
}

variable "db_user_password_ssm_param" {
  type        = string
  default     = null
  description = "Name of SSM Parameter that stores password for provisioned user. This param takes precedence other `db_user_password`"
}

variable "db_user_password_ssm_param_kms_key" {
  type        = string
  default     = null
  description = "Identifier of KMS key used for encryption of SSM Parameter that stores password for provisioned user"
}

variable "db_user_password" {
  type        = string
  description = "Password for the user that should be created and own (has all permission to) the provisioned database. Ignored if `db_user` is set to null"
  default     = null
}

variable "allowed_egress_cidr_blocks" {
  type        = list(string)
  description = "A list of CIDR blocks allowed to be reached from Lambda. Remember that Lambda needs to be able to communicate with AWS API"

  default = ["0.0.0.0/0"]
}
