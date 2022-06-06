
// ###################################################################################
// Local variables like domain name, bucket name and tags
// ###################################################################################
locals {
  domainName = "divisionby0.de"
  tags = {
    "Name"    = "DivisionBy0"
    "Project" = "Blog"
  }
}

// ###################################################################################
// DNS Zone
// ###################################################################################
resource "aws_route53_zone" "hosted_zone" {
  name = local.domainName
  tags = local.tags
}

# A record on apex domain pointing to vercel
resource "aws_route53_record" "root_record" {
  name    = local.domainName
  type    = "A"
  zone_id = aws_route53_zone.hosted_zone.id
  records = ["76.76.21.21"]
  ttl     = 300
}

# CNAME on sub domain pointing to vercel
resource "aws_route53_record" "www_record" {
  name    = "www.${local.domainName}"
  type    = "CNAME"
  zone_id = aws_route53_zone.hosted_zone.id
  records = ["cname.vercel-dns.com"]
  ttl     = 300
}

# Note that the IP address will be updated automatically by the nestingbox
resource "aws_route53_record" "nestingbox_record" {
  name    = "nestingbox.${local.domainName}"
  type    = "A"
  zone_id = aws_route53_zone.hosted_zone.id
  records = ["77.1.154.28"]
  ttl     = 300
}


// ###################################################################################
// Certificate
// ###################################################################################
resource "aws_acm_certificate" "domain_cert" {
  domain_name               = "*.${local.domainName}"
  subject_alternative_names = [local.domainName]
  validation_method         = "DNS"
  tags                      = local.tags
}

// Certificate validation records
resource "aws_route53_record" "certificate_validation_records" {
  for_each = {
    for dvo in aws_acm_certificate.domain_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }
  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = aws_route53_zone.hosted_zone.id
  records         = [each.value.record]
  ttl             = 60
}

// Certificate validation
resource "aws_acm_certificate_validation" "domain_cert_validation" {
  certificate_arn         = aws_acm_certificate.domain_cert.arn
  validation_record_fqdns = []
}
