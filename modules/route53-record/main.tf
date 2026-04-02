resource "aws_route53_record" "this" {
  zone_id = var.hosted_zone_id
  name    = var.subdomain == "" ? var.domain_name : "${var.subdomain}.${var.domain_name}"
  type    = var.type
  ttl     = var.ttl
  records = var.records

  # Allows Terraform to update the record even if it already exists in AWS
  allow_overwrite = true
}