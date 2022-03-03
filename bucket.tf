data "aws_s3_bucket" "logging" {
  bucket = var.logging_bucket
}

# enable logging to logging_bucket
data "aws_iam_policy_document" "allow_logging_to_logging_bucket" {
  statement {
    sid = "S3PolicyLoggingAccessStmt"
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${data.aws_s3_bucket.logging.arn}/*"]
  }
}

# attach logging policy to logging_bucket
resource "aws_s3_bucket_policy" "allow_logging_to_logging_bucket" {
  bucket = data.aws_s3_bucket.logging.id
  policy = data.aws_iam_policy_document.allow_logging_to_logging_bucket.json
}

# rotating KMS key for S3
resource "aws_kms_key" "s3_key" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

# Data bucket for SFTP server, tfsec warnings supressed as aws provider > 4 has not been supported yet
# tfsec:ignore:aws-s3-enable-bucket-logging
# tfsec:ignore:aws-s3-enable-versioning
# tfsec:ignore:aws-s3-enable-bucket-encryption
# tfsec:ignore:aws-s3-encryption-customer-key
# tfsec:ignore:aws-s3-enable-default-server-side-encryption
resource "aws_s3_bucket" "sftp" {
  bucket_prefix = "${local.prefix_kebab}sftpbucket"
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.sftp.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.sftp.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.sftp.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "this" {
  bucket        = aws_s3_bucket.sftp.id
  target_bucket = data.aws_s3_bucket.logging.id
  target_prefix = var.prefix
}

# block all public access to data bucket
resource "aws_s3_bucket_public_access_block" "sftp" {
  bucket                  = aws_s3_bucket.sftp.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
