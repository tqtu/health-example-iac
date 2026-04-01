variable "domain_name" {
  type        = string
  description = "The root domain (e.g., unboundshare.com)"
}

variable "subdomain" {
  type        = string
  description = "The prefix (e.g., 'qa' or 'www'). Empty string for the root domain."
}

variable "hosted_zone_id" {
  type        = string
  description = "The ID of the Hosted Zone where this record will be created"
}

variable "s3_website_endpoint" {
  type        = string
  description = "The website endpoint provided by the S3 bucket"
}

variable "s3_hosted_zone_id" {
  type        = string
  description = "The specific Hosted Zone ID for the S3 bucket region (e.g., Z3O0J2DX0C6PQG for ap-southeast-1)"
}

variable "common_tags" {
  type        = map(string)
  description = "A map of tags to apply to resources (Note: Route 53 Records do not support tags)"
  default     = {}
}