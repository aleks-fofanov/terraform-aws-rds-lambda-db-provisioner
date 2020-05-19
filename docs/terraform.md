## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 0.12.0 |
| archive | ~> 1.3 |
| aws | ~> 2.31 |
| local | ~> 1.2 |

## Providers

| Name | Version |
|------|---------|
| archive | ~> 1.3 |
| aws | ~> 2.31 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| allowed\_egress\_cidr\_blocks | A list of CIDR blocks allowed to be reached from Lambda. Remember that Lambda needs to be able to communicate with AWS API | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| attributes | Additional attributes, e.g. `1` | `list(string)` | `[]` | no |
| db\_instance\_id | DB Instance Identifier | `string` | n/a | yes |
| db\_instance\_security\_group\_id | DB instance security group to add rules to. Rules will allow communication between Lambda and DB instance | `string` | `null` | no |
| db\_master\_password | DB Instance master password. The usage of this parameter is discouraged. Consider putting db password in SSM Parameter Store and passing its ARN to the module via `db_master_password_ssm_parameter_arn` parameter | `string` | `null` | no |
| db\_master\_password\_ssm\_param | Name of SSM Parameter that stores password for master user. This param takes precendence other `db_master_password` | `string` | `null` | no |
| db\_master\_password\_ssm\_param\_kms\_key | Identifier of KMS key used for encryption of SSM Parameter that stores password for master user | `string` | `null` | no |
| db\_name | Database name that should be created | `string` | n/a | yes |
| db\_user | Name of user that should be created and own (has all persmiison to) the provisioned database. If left empty, no user will be created | `string` | `null` | no |
| db\_user\_password | Password for the user that should be created and own (has all persmiison to) the provisioned database. Ignored if `db_user` is set to null | `string` | `null` | no |
| db\_user\_password\_ssm\_param | Name of SSM Parameter that stores password for provisioned user. This param takes precendence other `db_user_password` | `string` | `null` | no |
| db\_user\_password\_ssm\_param\_kms\_key | Identifier of KMS key used for encryption of SSM Parameter that stores password for provisioned user | `string` | `null` | no |
| delimiter | Delimiter to be used between `namespace`, `name`, `stage` and `attributes` | `string` | `"-"` | no |
| enabled | Defines whether this module should create resources | `bool` | `true` | no |
| invoke | Defines whether lambda function should be invoked immediately after provisioning | `bool` | `true` | no |
| kms\_key | KMS key identifier. Acceptes the same format as KMS key data source (https://www.terraform.io/docs/providers/aws/d/kms_key.html). If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key. | `string` | `null` | no |
| logs\_kms\_key\_id | KMS Key Id for Lambda function logs ecnryption | `string` | `null` | no |
| logs\_retention\_days | Lambda function logs retentions in days | `number` | `null` | no |
| memory | Amount of memory in MB your Lambda Function can use at runtime | `number` | `256` | no |
| name | Solution name, e.g. 'app' or 'jenkins' | `string` | `"rds"` | no |
| namespace | Namespace (e.g. `cp` or `cloudposse`) | `string` | `""` | no |
| stage | Stage (e.g. `prod`, `dev`, `staging`) | `string` | `""` | no |
| tags | Additional tags (e.g. `map(`BusinessUnit`,`XYZ`)` | `map(string)` | `{}` | no |
| timeout | The amount of time your Lambda Function has to run in seconds | `number` | `30` | no |
| vpc\_config | VPC configuratiuon for Lambda function | <pre>object({<br>    vpc_id             = string<br>    subnet_ids         = list(string)<br>    security_group_ids = list(string)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| lambda\_function\_arn | Lambda Function ARN |
| lambda\_function\_name | Lambda Function name |
| lambda\_iam\_policy\_arn | Lambda IAM Policy ARN |
| lambda\_iam\_policy\_id | Lambda IAM Policy ID |
| lambda\_iam\_policy\_name | Lambda IAM Policy name |
| lambda\_iam\_role\_arn | Lambda IAM Role ARN |
| lambda\_iam\_role\_id | Lambda IAM Role ID |
| lambda\_iam\_role\_name | Lambda IAM Role name |
