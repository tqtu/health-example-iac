resource "aws_route53_record" "env_record" {
  zone_id = var.hosted_zone_id

  # Logic: Creates 'qa.domain.com' or just 'domain.com'
  name    = var.subdomain == "" ? var.domain_name : "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.s3_website_endpoint
    zone_id                = var.s3_hosted_zone_id
    evaluate_target_health = false
  }
}

output "name_servers" {
  value = var.hosted_zone_id # This is wrong, see fix below
}