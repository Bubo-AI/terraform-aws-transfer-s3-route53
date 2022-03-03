# SFTP Server with custom domain on AWS

This terraform module creates an SFTP server with a custom subdomain and multiple users. Each user has its own directory under the same bucket created upon deployment. You can deploy this module several times in the same account using different prefixes. Each deployment creates an S3 bucket to keep users data but different users can not see each others files.

This module creates a public AWS Transfer Service configured to use a lambda as an identity provider to authenticate one or more users against stored credentials in the AWS Secrets.

> After deploying this service, go to the secret manager and replace the secret key `Password` for each user with a bcrypt hash. Default value for password is `REPLACE_ME` (as plain text). To generate a bcrypt hash, use the command below and replace `PASSWORDHERE` with your own password.
> ```python
> python -c 'import bcrypt; print(bcrypt.hashpw("PASSWORDHERE".encode("utf-8"), bcrypt.gensalt()))'
> ```

## Requirements

This module assumes you have a DNS Zone in AWS. An alias (CNAME) record will be created for every member of `subdomains` variable.

> **This module is only available in \*nix environment where python3 is available.**
>
> In order to deploy the lambda script with `bcrypt` dependency, you need to have `python` available in the `PATH`. `bcrypt` and its dependencies will be installed via `python -m pip` command. This module install dependencies to match with lambda runtime which is Python 3.9. For more information, please refer to [python packager module](https://github.com/Bubo-AI/terraform-python-packager).


## Usage

    $ terraform init
    $ terraform plan
    $ terraform apply

## Example User Configuration

Once the service has been deployed, a sample user will be created in the secret manager with the following configuration:

Secret Name: `prefix`-SFTP/user1


| UserId | HomeDirectoryDetails | Role | Password | _AcceptedIpNetwork*_ |
|--------|----------------------|------|----------|-------------------|
| user1 | `[{\"Entry\": \"/\", \"Target\": \"/s3_bucket/user1\"}]` | arn:aws:iam::`ACCOUNT_ID`:role/`prefix`-transfer-user-iam-role-user1 | `BCRPYT_HASH` | `192.168.1.0/24` |

**user1** is chroot'd to the **/s3_bucket/user1** directory in S3.

\* **_AcceptedIpNetwork_** is an optional CIDR for the allowed client source IP address range. You can specify multiple CIDR by separating with comma, e.g.: `192.0.0.0/24, 224.0.0.0/16`. Please note that ignored bits in the CIDR should be zero. For instance, 192.168.1.1/24 is an invalid CIDR as 24th bith onwards should be zero. Therefore the correct version is `192.168.1.0/24`.


## Example Usage

```hcl
module "sftp_server" {
  source         = "github.com/Bubo-AI/terraform-aws-transfer-s3-route53?ref=v0.1.0"
  usernames      = ["sftp_user_1", "sftp_user_2"]
  prefix         = "acme"
  subdomains     = ["sftp"]
  r53_zone       = "acme.com"
  logging_bucket = "acme-sftp-access-logs"
}

```

Fully working example can be found in [`examples`](examples/).


## Outputs

| Name                 | Description                                          |
|----------------------|------------------------------------------------------|
| usernames            | List of usernames created                            |
| roles                | The roles created for each user                      |
| user_secrets         | The secret manager keys created for each user        |
| bucket_id            | The bucket where AWS Transfer is connected to        |
| bucket_kms_key       | KMS key used to encrypt S3 bucket                    |
| secret_kms_key       | KMS key used to encrypt Secret Manager secretts      |
| transfer_endpoint    | The endpoint of the AWS Transfer service             |
| route53_endpoint     | Subdomains created as an alias to transfer_endpoint  |

