# rotating KMS key for secret manager
resource "aws_kms_key" "secret_key" {
  description             = "This key is used to encrypt secret manager objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}


resource "aws_secretsmanager_secret" "user" {
  for_each    = toset(var.usernames)
  name        = "${local.prefix_kebab}SFTP/${each.key}"
  description = "SFTP User - ${each.key} for ${var.prefix}"
  kms_key_id  = aws_kms_key.secret_key.arn

  tags = {
    Resource = "SFTP"
    User     = each.key
    Prefix   = var.prefix
  }
}

resource "aws_secretsmanager_secret_version" "user" {
  for_each = toset(var.usernames)

  secret_id     = aws_secretsmanager_secret.user[each.key].id
  secret_string = <<-EOF
    {
      "HomeDirectoryDetails": "[{\"Entry\": \"/\", \"Target\": \"/${aws_s3_bucket.sftp.id}/${each.key}\"}]",
      "Password": "REPLACE_ME",
      "Role": "${aws_iam_role.transfer[each.key].arn}",
      "UserId": "${each.key}",
      "AcceptedIpNetwork": "0.0.0.0/0"
    }
  EOF
}

# allow lambda to access KMS to decrypt secrets
data "aws_iam_policy_document" "lambda_kms_use" {
  statement {
    sid    = "AllowKMSuse"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyPair",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:GenerateDataKeyPairWithoutPlaintext",
      "kms:DescribeKey",
    ]
    resources = [aws_kms_key.secret_key.arn]
  }
}

resource "aws_iam_policy" "kms_use" {
  name        = "${local.prefix_kebab}kmsuse"
  description = "Policy to allow use of KMS Key"
  policy      = data.aws_iam_policy_document.lambda_kms_use.json
}

resource "aws_iam_role_policy_attachment" "lambda_kms_role_policy" {
  role       = module.idp.lambda_iam_role
  policy_arn = aws_iam_policy.kms_use.arn
}
