# AWS RDS Lambda database provisioner

## Introduction

This module provisions an AWS lambda function which creates a new database and optionally a new user in RDS instance
within a VPC. Supported engines are `postgres` and `mysql`. A newly created user or a master user (in case when you
don't need a new user) will be granted all permissions to the created database.

This module is aim to solve a **cold-start problem** - when you execute `terraform apply` and all your
infrastructure is provisioned in one run. If are trying to solve a different problem, then you
should be optimizing for Day 2 operations and provision a database by other means  (e.g. using 
[terraform postrgres provider](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs)).

**Features**:
- Master user password as well as new user password can be passed to the module either via
    - Module variables
    - Parameters in SSM Parameter Store (**Recommended!**)
    - Secrets in Secrets Manager (**Recommended!**)
- Lambda function execution logs are shipped to Cloudwatch
- No database or user will be created if they already exist

**Notes on using secrets from AWS Secrets Manager**:
- When [referencing secrets stored in Secrets Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/integration-ps-secretsmanager.html),
  the `/aws/reference/secretsmanager` prefix must be used
- A secret must contain password in the `password` field or be a plain-text secret

**Caveats**:
- This lambda function needs internet access in order to comminitcate with AWS API. You need to associate this
  function with one or more private subnets in your VPC and make sure that their routing tables have a default
  route pointing to NAT Gateway or NAT Instance in a public subnet. Associating a lambda function with a public
  subnet doesn't give it internet connectivity or public IP address. More context:
  [Give Internet Access to a Lambda Function in a VPC](https://aws.amazon.com/premiumsupport/knowledge-center/internet-access-lambda-function/)
- This lambda function **DOES NOT DROP provisioned database or user** on destroy in order to prevent accidental data
  loss. Please make sure to delete provisioned database and user manually.
- ENIs attached to a lambda function may cause `DependencyViolation` error when you try to destroy associated
  security groups and/or subnets.
  More context: [Corresponding issue on github](https://github.com/terraform-providers/terraform-provider-aws/issues/10329)

**Backlog**:
- [ ] Support SSL connections to RDS

This module is backed by best of breed terraform modules maintained by [Cloudposse](https://github.com/cloudposse).

## Terraform versions

Terraform 0.12. Pin module version to `~> 1.0`. Submit pull-requests to `terraform012` branch.

Terraform 0.13. Pin module version to `~> 2.0`. Submit pull-requests to `master` branch.

## Usage

### Simple usage example

The following example creates a database `new_database` and a user `new_user` with the passwords
passed via variables.

```hcl
  module "db_provisioner" {
    source  = "aleks-fofanov/rds-lambda-db-provisioner/aws"
    version = "~> 2.0"
    
    source    = "git::https://github.com/aleks-fofanov/terraform-aws-rds-lambda-db-provisioner.git?ref=master"
    name      = "stack"
    namespace = "cp"
    stage     = "prod"

    db_instance_id                = "prod-stack-db"
    db_instance_security_group_id = "sg-XXXXXXXX"
    db_master_password            = "XXXXXXXX"

    db_name          = "new_database"
    db_user          = "new_user"
    db_user_password = "XXXXXXXX"

    vpc_config = {
      vpc_id             = "vpc-XXXXXXXX"
      subnet_ids         = ["subnet-XXXXXXXX", "subnet-XXXXXXXX"]
      security_group_ids = []
    }
  }
```

### Example with passwords passed via SSM Parameters

This example creates a database `new_database` and a user `new_user` with the passwords
passed via SSM Parameters.

```hcl
module "db_provisioner" {
  source  = "aleks-fofanov/rds-lambda-db-provisioner/aws"
  version = "~> 2.0"
  
  name      = "stack"
  namespace = "cp"
  stage     = "prod"

  db_instance_id                       = "prod-stack-db"
  db_instance_security_group_id        = "sg-XXXXXXXX"
  db_master_password_ssm_param         = "/cp/prod/stack/database/master_password"
  db_master_password_ssm_param_kms_key = "alias/aws/ssm"

  db_name                            = "new_database"
  db_user                            = "new_user"
  db_user_password_ssm_param         = "/cp/prod/stack/database/new_user_password"
  db_user_password_ssm_param_kms_key = "alias/aws/ssm"

  vpc_config = {
    vpc_id             = "vpc-XXXXXXXX"
    subnet_ids         = ["subnet-XXXXXXXX", "subnet-XXXXXXXX"]
    security_group_ids = []
  }
}
```

### Example without creating a new user

This example creates a database `new_database` without a new user with the master user password
passed via SSM Parameter.

```hcl
module "db_provisioner" {
  source  = "aleks-fofanov/rds-lambda-db-provisioner/aws"
  version = "~> 2.0"
  
  name      = "stack"
  namespace = "cp"
  stage     = "prod"

  db_instance_id                       = "prod-stack-db"
  db_instance_security_group_id        = "sg-XXXXXXXX"
  db_master_password_ssm_param         = "/cp/prod/stack/database/master_password"
  db_master_password_ssm_param_kms_key = "alias/aws/ssm"

  db_name = "new_database"

  vpc_config = {
    vpc_id             = "vpc-XXXXXXXX"
    subnet_ids         = ["subnet-XXXXXXXX", "subnet-XXXXXXXX"]
    security_group_ids = []
  }
}
```

Please refer to the `examples` folder for a complete example.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13.0 |
| <a name="requirement_archive"></a> [archive](#requirement\_archive) | >= 2.1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >= 2.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | >= 2.1.0 |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aggregated_policy"></a> [aggregated\_policy](#module\_aggregated\_policy) | cloudposse/iam-policy-document-aggregator/aws | 0.8.0 |
| <a name="module_default_label"></a> [default\_label](#module\_default\_label) | cloudposse/label/null | 0.24.1 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.basic_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.default_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.vpc_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_alias.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_alias) | resource |
| [aws_lambda_function.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.egress_blocks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.egress_from_lambda_to_db_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.ingress_to_db_instance_from_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [archive_file.default](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_db_instance.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/db_instance) | data source |
| [aws_iam_policy_document.assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.default_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.lambda_kms_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.master_password_kms_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.master_password_secretsmanager_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.master_password_ssm_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.user_password_kms_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.user_password_secretsmanager_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.user_password_ssm_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_kms_key.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_kms_key.master_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_kms_key.user_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |
| [aws_lambda_invocation.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_invocation) | data source |
| [aws_partition.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_secretsmanager_secret.master_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_secretsmanager_secret.user_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret) | data source |
| [aws_ssm_parameter.master_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.user_password](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_egress_cidr_blocks"></a> [allowed\_egress\_cidr\_blocks](#input\_allowed\_egress\_cidr\_blocks) | A list of CIDR blocks allowed to be reached from Lambda. Remember that Lambda needs to be able to communicate with AWS API | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | Additional attributes, e.g. `1` | `list(string)` | `[]` | no |
| <a name="input_db_instance_id"></a> [db\_instance\_id](#input\_db\_instance\_id) | DB Instance Identifier | `string` | n/a | yes |
| <a name="input_db_instance_security_group_id"></a> [db\_instance\_security\_group\_id](#input\_db\_instance\_security\_group\_id) | DB instance security group to add rules to. Rules will allow communication between Lambda and DB instance | `string` | `null` | no |
| <a name="input_db_master_password"></a> [db\_master\_password](#input\_db\_master\_password) | DB Instance master password. The usage of this parameter is discouraged. Consider putting db password in SSM Parameter Store and passing its ARN to the module via `db_master_password_ssm_parameter_arn` parameter | `string` | `null` | no |
| <a name="input_db_master_password_ssm_param"></a> [db\_master\_password\_ssm\_param](#input\_db\_master\_password\_ssm\_param) | Name of SSM Parameter that stores password for master user. This param takes precedence other `db_master_password` | `string` | `null` | no |
| <a name="input_db_master_password_ssm_param_kms_key"></a> [db\_master\_password\_ssm\_param\_kms\_key](#input\_db\_master\_password\_ssm\_param\_kms\_key) | Identifier of KMS key used for encryption of SSM Parameter that stores password for master user | `string` | `null` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Database name that should be created | `string` | n/a | yes |
| <a name="input_db_user"></a> [db\_user](#input\_db\_user) | Name of user that should be created and own (has all permission to) the provisioned database. If left empty, no user will be created | `string` | `null` | no |
| <a name="input_db_user_password"></a> [db\_user\_password](#input\_db\_user\_password) | Password for the user that should be created and own (has all permission to) the provisioned database. Ignored if `db_user` is set to null | `string` | `null` | no |
| <a name="input_db_user_password_ssm_param"></a> [db\_user\_password\_ssm\_param](#input\_db\_user\_password\_ssm\_param) | Name of SSM Parameter that stores password for provisioned user. This param takes precedence other `db_user_password` | `string` | `null` | no |
| <a name="input_db_user_password_ssm_param_kms_key"></a> [db\_user\_password\_ssm\_param\_kms\_key](#input\_db\_user\_password\_ssm\_param\_kms\_key) | Identifier of KMS key used for encryption of SSM Parameter that stores password for provisioned user | `string` | `null` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between `namespace`, `name`, `stage` and `attributes` | `string` | `"-"` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Defines whether this module should create resources | `bool` | `true` | no |
| <a name="input_invoke"></a> [invoke](#input\_invoke) | Defines whether lambda function should be invoked immediately after provisioning | `bool` | `true` | no |
| <a name="input_kms_key"></a> [kms\_key](#input\_kms\_key) | KMS key identifier. Accepts the same format as KMS key data source (https://www.terraform.io/docs/providers/aws/d/kms_key.html). If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key. | `string` | `null` | no |
| <a name="input_logs_kms_key_id"></a> [logs\_kms\_key\_id](#input\_logs\_kms\_key\_id) | KMS Key Id for Lambda function logs ecnryption | `string` | `null` | no |
| <a name="input_logs_retention_days"></a> [logs\_retention\_days](#input\_logs\_retention\_days) | Lambda function logs retentions in days | `number` | `null` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Amount of memory in MB your Lambda Function can use at runtime | `number` | `256` | no |
| <a name="input_name"></a> [name](#input\_name) | Solution name, e.g. 'app' or 'jenkins' | `string` | `"rds"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace (e.g. `cp` or `cloudposse`) | `string` | `""` | no |
| <a name="input_stage"></a> [stage](#input\_stage) | Stage (e.g. `prod`, `dev`, `staging`) | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `map(`BusinessUnit`,`XYZ`)` | `map(string)` | `{}` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | The amount of time your Lambda Function has to run in seconds | `number` | `30` | no |
| <a name="input_vpc_config"></a> [vpc\_config](#input\_vpc\_config) | VPC configuration for Lambda function | <pre>object({<br>    vpc_id             = string<br>    subnet_ids         = list(string)<br>    security_group_ids = list(string)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_lambda_function_arn"></a> [lambda\_function\_arn](#output\_lambda\_function\_arn) | Lambda Function ARN |
| <a name="output_lambda_function_name"></a> [lambda\_function\_name](#output\_lambda\_function\_name) | Lambda Function name |
| <a name="output_lambda_iam_policy_arn"></a> [lambda\_iam\_policy\_arn](#output\_lambda\_iam\_policy\_arn) | Lambda IAM Policy ARN |
| <a name="output_lambda_iam_policy_id"></a> [lambda\_iam\_policy\_id](#output\_lambda\_iam\_policy\_id) | Lambda IAM Policy ID |
| <a name="output_lambda_iam_policy_name"></a> [lambda\_iam\_policy\_name](#output\_lambda\_iam\_policy\_name) | Lambda IAM Policy name |
| <a name="output_lambda_iam_role_arn"></a> [lambda\_iam\_role\_arn](#output\_lambda\_iam\_role\_arn) | Lambda IAM Role ARN |
| <a name="output_lambda_iam_role_id"></a> [lambda\_iam\_role\_id](#output\_lambda\_iam\_role\_id) | Lambda IAM Role ID |
| <a name="output_lambda_iam_role_name"></a> [lambda\_iam\_role\_name](#output\_lambda\_iam\_role\_name) | Lambda IAM Role name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is created and maintained by [Aleksandr Fofanov](https://github.com/aleks-fofanov).

## License

Apache 2 Licensed. See LICENSE for full details.

## Help

**Got a question?**

File a GitHub [issue](https://github.com/aleks-fofanov/terraform-aws-rds-lambda-db-provisioner/issues).
