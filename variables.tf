
variable "logging_bucket" {
  description = "S3 bucket to store access logs of the data bucket."
  default     = ""
  type        = string
  validation {
    condition     = can(regex("[a-z0-9][a-z0-9-]{1,61}[a-z0-9]", var.logging_bucket))
    error_message = "Invalid s3 bucket name."
  }
}

variable "subdomains" {
  description = "List of subdomain names to redirect AWS transfer endpoint. Mostly same as the prefix."
  default     = []
  type        = list(string)
  validation {
    condition = length([
      for s in var.subdomains : s
      if can(regex("^[a-z0-9-]+$", s))
    ]) == length(var.subdomains)
    error_message = "The subdomains must consist of lowercase alphanumeric characters and/or a hyphen."
  }
}

variable "prefix" {
  description = "AWS resource prefix"
  default     = ""
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.prefix))
    error_message = "The prefix must consist of lowercase alphanumeric characters and a hyphen."
  }
}

variable "r53_zone" {
  description = "Route53 Zone Name"
  type        = string
}


variable "usernames" {
  description = "SFTP usernames as list"
  type        = list(string)
  default     = ["transfer-user"]
}
