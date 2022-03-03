resource "aws_iam_role" "transfer" {
  for_each = toset(var.usernames)
  name     = "${local.prefix_kebab}transfer-user-iam-role-${each.key}"

  assume_role_policy = <<EOF
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
EOF
}

resource "aws_iam_role_policy" "transfer" {
  for_each = toset(var.usernames)

  name = "${local.prefix_kebab}transfer-user-iam-policy-${each.key}"
  role = aws_iam_role.transfer[each.key].id

  policy = <<-POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "AllowListingOfUserFolder",
          "Action": [
              "s3:ListBucket",
              "s3:GetBucketLocation"
          ],
          "Effect": "Allow",
          "Resource": [
              "${aws_s3_bucket.sftp.arn}"
          ],
          "Condition": {
              "StringLike": {
                  "s3:prefix": [
                      "${each.key}/*",
                      "${each.key}"
                  ]
              }
          }
      },
      {
          "Sid": "HomeDirObjectAccess",
          "Effect": "Allow",
          "Action": [
              "s3:PutObject",
              "s3:GetObject",
              "s3:DeleteObjectVersion",
              "s3:DeleteObject",
              "s3:GetObjectVersion"
          ],
          "Resource": [
              "${aws_s3_bucket.sftp.arn}/${each.key}",
              "${aws_s3_bucket.sftp.arn}/${each.key}/*"
          ]
       },
       {
           "Sid": "EncryptionKeyAccess",
            "Action": [
                "kms:Decrypt",
                "kms:Encrypt",
                "kms:GenerateDataKey",
                "kms:DescribeKey",
                "kms:ReEncrypt"
            ],
            "Effect": "Allow",
            "Resource": "${aws_kms_key.s3_key.arn}"
       }
  ]
}
  POLICY
}
