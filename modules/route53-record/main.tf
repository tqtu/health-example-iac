resource "aws_route53_record" "env_record" {
  zone_id = var.hosted_zone_id

  # Logic: If subdomain is empty, use root domain. Otherwise, use subdomain.
  name    = var.subdomain == "" ? var.domain_name : "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    # The S3 Website Endpoint (e.g., s3-website-ap-southeast-1.amazonaws.com)
    name                   = var.s3_website_endpoint

    # The target Hosted Zone ID for the S3 bucket's region
    zone_id                = var.s3_hosted_zone_id
    evaluate_target_health = false
  }

  # Lifecycle prevents accidental record deletion during updates
  lifecycle {
    create_before_destroy = true
  }
}