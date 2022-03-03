data "aws_route53_zone" "this" {
  name         = var.r53_zone
  private_zone = false
}

# if more than one subdomain names specified, create a new record set for each
resource "aws_route53_record" "this" {
  for_each = toset(var.subdomains)
  type     = "CNAME"
  name     = each.key
  ttl      = 600
  records  = [aws_transfer_server.sftp.endpoint]
  zone_id  = data.aws_route53_zone.this.zone_id
}

# associate the first subdomain with the sftp server endpoint
resource "null_resource" "associate_custom_hostname" {
  provisioner "local-exec" {
    command = <<EOF
aws transfer tag-resource \
  --arn '${aws_transfer_server.sftp.arn}' \
  --tags \
    'Key=aws:transfer:customHostname,Value=${var.subdomains[0]}.${data.aws_route53_zone.this.name}' \
    'Key=aws:transfer:route53HostedZoneId,Value=/hostedzone/${data.aws_route53_zone.this.zone_id}'
EOF
  }
  depends_on = [aws_transfer_server.sftp, data.aws_route53_zone.this, aws_route53_record.this]
}
