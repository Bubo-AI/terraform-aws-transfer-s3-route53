module "sftp_server" {
  source         = "../"
  usernames      = ["sftp_user_1", "sftp_user_2"]
  prefix         = "acme"
  subdomains     = ["sftp"]
  r53_zone       = "acme.com"
  logging_bucket = "acme-sftp-access-logs"
}
