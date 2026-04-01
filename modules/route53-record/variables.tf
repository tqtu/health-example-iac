variable "subdomain" {
  description = "The subdomain prefix (e.g., 'qa' or 'www'). Leave as empty string for root domain."
  type        = string
  # No default here, forcing the environment to define it
}

variable "domain_name" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "s3_website_endpoint" {
  type = string
}

variable "s3_hosted_zone_id" {
  type = string
}