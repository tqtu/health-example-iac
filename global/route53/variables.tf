variable "domain_name" {
  type        = string
  description = "The root domain (e.g., unboundshare.com)"
}

variable "subdomain" {
  type        = string
  description = "The prefix (e.g., 'qa' or 'www'). Empty for root."
}

variable "hosted_zone_id" {
  type        = string
  description = "The ID from the aws_route53_zone resource"
}

variable "s3_website_endpoint" {
  type        = string
}

variable "s3_hosted_zone_id" {
  type        = string
}

variable "common_tags" {
  type = map(string)
}