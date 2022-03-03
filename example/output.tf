output "usernames" {
  value = module.sftp_server.usernames
}

output "roles" {
  value = module.sftp_server.roles
}

output "user_secrets" {
  value = module.sftp_server.user_secrets
}

output "bucket_id" {
  value = module.sftp_server.bucket_id
}

output "bucket_kms_key" {
  value = module.sftp_server.bucket_kms_key
}

output "secret_kms_key" {
  value = module.sftp_server.secret_kms_key
}

output "transfer_endpoint" {
  value = module.sftp_server.transfer_endpoint
}

output "route53_endpoint" {
  value = module.sftp_server.route53_endpoint
}

