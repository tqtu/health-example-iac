resource "aws_route53_record" "env_record" {
  zone_id = var.hosted_zone_id

  # Logic: Creates 'qa.unboundshare.com' or 'unboundshare.com'
  name    = var.subdomain == "" ? var.domain_name : "${var.subdomain}.${var.domain_name}"

  # Use CNAME for learning; it's easier when bucket names don't match
  type    = "CNAME"
  ttl     = "300"
  records = [var.s3_website_endpoint]
}

data "aws_route53_zone" "selected" {
  zone_id = var.hosted_zone_id
}

output "name_servers" {
  value = data.aws_route53_zone.selected.name_servers
}