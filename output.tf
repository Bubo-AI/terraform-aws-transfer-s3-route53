output "usernames" {
  value = var.usernames
}

output "roles" {
  value = {
    for k, v in aws_iam_role.transfer : k => v.name
  }
}

output "user_secrets" {
  value = {
    for k, v in aws_secretsmanager_secret.user : k => v.name
  }
}

output "bucket_id" {
  value = aws_s3_bucket.sftp.id
}

output "bucket_kms_key" {
  value = aws_kms_key.s3_key.arn
}

output "secret_kms_key" {
  value = aws_kms_key.secret_key.arn
}

output "transfer_endpoint" {
  value = aws_transfer_server.sftp.endpoint
}

output "route53_endpoint" {
  value = [
    for k, v in aws_route53_record.this : "${v.name}.${data.aws_route53_zone.this.name}"
  ]
}

