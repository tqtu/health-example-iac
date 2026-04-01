variable "hosted_zone_id" {}
variable "domain_name" {}
variable "subdomain" {}
variable "type" { default = "CNAME" }
variable "ttl" { default = 300 }
variable "records" { type = list(string) }