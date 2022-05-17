data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# role for SFTP server
resource "aws_iam_role" "sftp" {
  name = "${local.prefix_kebab}sftp-server-iam-role"

  assume_role_policy = <<-POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "transfer.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]
    }
  POLICY
}

resource "aws_iam_role" "sftp_log" {
  # log role for SFTP server
  name = "${local.prefix_kebab}sftp-server-iam-log-role"

  assume_role_policy = <<-POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "transfer.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]
    }
  POLICY
}

resource "aws_iam_role_policy" "sftp" {
  # policy to allow invocation of IdP API
  name = "${local.prefix_kebab}sftp-server-iam-policy"
  role = aws_iam_role.sftp.id

  policy = <<-POLICY
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "InvokeApi",
          "Effect": "Allow",
          "Action": [
            "execute-api:Invoke"
          ],
          "Resource": "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${module.idp.rest_api_id}/${module.idp.rest_api_stage_name}/GET/*"
        },
        {
          "Sid": "ReadApi",
          "Effect": "Allow",
          "Action": [
            "apigateway:GET"
          ],
          "Resource": "*"
        }
      ]
    }
  POLICY
}

resource "aws_iam_role_policy" "sftp_log" {
  # policy to allow logging to Cloudwatch
  name = "${local.prefix_kebab}sftp-server-iam-log-policy"
  role = aws_iam_role.sftp_log.id

  policy = <<-POLICY
    {
      "Version": "2012-10-17",
      "Statement": [{
          "Sid": "AmazonAPIGatewayPushToCloudWatchLogs",
          "Effect": "Allow",
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
            "logs:GetLogEvents",
            "logs:FilterLogEvents"
          ],
          "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/transfer/${aws_transfer_server.sftp.id}*"
        }
      ]
    }
  POLICY
}

resource "aws_transfer_server" "sftp" {
  identity_provider_type = "API_GATEWAY"
  logging_role           = aws_iam_role.sftp_log.arn
  url                    = module.idp.invoke_url # url from output of the module
  invocation_role        = aws_iam_role.sftp.arn
  endpoint_type          = "PUBLIC"

  tags = {
    NAME = "${local.prefix_kebab}sftp-server"
  }
}

module "idp" {
  source = "github.com/Bubo-AI/terraform-aws-transfer?ref=v0.5.4"
  prefix = var.prefix
}
