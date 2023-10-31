
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
  records = ["77.8.156.16"]
  ttl     = 300
}
