variable "env" {}

variable "common_tags" {}

variable "domain_name" {
  description = "The root domain (unboundshare.com)"
}

variable "s3_bucket_domain_name" {
  description = "The S3 website endpoint"
}