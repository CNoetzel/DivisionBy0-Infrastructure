
terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.0"
    }
  }
}

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

// ###################################################################################
// Let' Encrypt Certificate
// ###################################################################################

provider "acme" {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "webmaster@${local.domainName}"
}

resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.registration.account_key_pem
  common_name               = aws_route53_zone.hosted_zone.name
  subject_alternative_names = ["*.${aws_route53_zone.hosted_zone.name}"]

  dns_challenge {
    provider = "route53"

    config = {
      AWS_HOSTED_ZONE_ID      = aws_route53_zone.hosted_zone.zone_id
      AWS_POLLING_INTERVAL    = 30
      AWS_PROPAGATION_TIMEOUT = 600
    }
  }
}

resource "aws_s3_bucket" "certificate_bucket" {
  bucket = "lets-encrypt-certificate"

  server_side_encryption_configuration {
    rule {
      bucket_key_enabled = false
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_object" "certificate_artifacts_s3_objects" {
  for_each = toset(["certificate_pem", "issuer_pem", "private_key_pem"])

  bucket  = aws_s3_bucket.certificate_bucket.id
  key     = "ssl-certs/${each.key}"
  content = lookup(acme_certificate.certificate, "${each.key}")
}
