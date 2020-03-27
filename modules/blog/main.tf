// ###################################################################################
// Local variables like domain name, bucket name and tags
// ###################################################################################
locals {
  domainName      = "divisionby0.de"
  s3_bucket_name  = "divisionby0-blog"
  tags = {
    "Name"    = "DivisionBy0"
    "Project" = "Blog"
  }
}

// ###################################################################################
// Provider as Cloudfront and Certificate have to be created in us-east-1
// ###################################################################################
provider "aws" {
  region = "us-east-1"
  alias = "east"
}

// ###################################################################################
// Cloudfront origin access identity
// ###################################################################################
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "Access identity to access s3 bucket from cloudfront"
}

// ###################################################################################
// S3 bucket for blog
// ###################################################################################
resource "aws_s3_bucket" "blog_bucket" {
  bucket        = local.s3_bucket_name
  acl           = "private"
  force_destroy = false
  tags          = local.tags
  policy        = <<EOF
{
  "Version": "2012-10-17",
  "Id": "PolicyForCloudfrontOriginAccessIdentity",
  "Statement": [
    {
      "Sid": "Grant OAI read access to bucket",
      "Action": ["s3:GetObject", "s3:ListBucket"],
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"
      },
      "Resource": [
        "arn:aws:s3:::${local.s3_bucket_name}",
        "arn:aws:s3:::${local.s3_bucket_name}/*"
      ]
    }
  ]
}
EOF
}

// ###################################################################################
// DNS Zone
// ###################################################################################
resource "aws_route53_zone" "hosted_zone" {
  name = local.domainName
  tags = local.tags
}

resource "aws_route53_record" "root_record" {
  name = local.domainName
  type = "A"
  zone_id = aws_route53_zone.hosted_zone.id

  alias {
    evaluate_target_health = false
    name = aws_cloudfront_distribution.blog_cloudfront_distribution.domain_name
    zone_id = aws_cloudfront_distribution.blog_cloudfront_distribution.hosted_zone_id
  }
}

resource "aws_route53_record" "www_record" {
  name = "www.${local.domainName}"
  type = "A"
  zone_id = aws_route53_zone.hosted_zone.id

  alias {
    evaluate_target_health = false
    name = aws_cloudfront_distribution.blog_cloudfront_distribution.domain_name
    zone_id = aws_cloudfront_distribution.blog_cloudfront_distribution.hosted_zone_id
  }
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
  provider                  = aws.east
  domain_name               = "*.${local.domainName}"
  subject_alternative_names = [local.domainName]
  validation_method         = "DNS"
  tags                      = local.tags
}

// Certificate validation records
resource "aws_route53_record" "certificate_validation_records" {
  name    = aws_acm_certificate.domain_cert.domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.domain_cert.domain_validation_options[0].resource_record_type
  zone_id = aws_route53_zone.hosted_zone.id
  records = [aws_acm_certificate.domain_cert.domain_validation_options[0].resource_record_value]
  ttl     = 60
}

// Certificate validation
resource "aws_acm_certificate_validation" "domain_cert_validation" {
  provider                = aws.east
  certificate_arn         = aws_acm_certificate.domain_cert.arn
  validation_record_fqdns = []
}

// ###################################################################################
// Cloudfront
// ###################################################################################
resource "aws_cloudfront_distribution" "blog_cloudfront_distribution" {
  provider            = aws.east
  enabled             = true
  price_class         = "PriceClass_100"
  comment             = "Cloudfront distribution for divisionby0 blog"
  aliases             = [local.domainName,  "www.${local.domainName}"]
  default_root_object = "index.html"
  tags                = local.tags

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD", "OPTIONS", "DELETE", "PATCH", "POST", "PUT"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = local.s3_bucket_name
    viewer_protocol_policy = "redirect-to-https"
    compress = true
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  origin {
    domain_name = aws_s3_bucket.blog_bucket.bucket_regional_domain_name
    origin_id = local.s3_bucket_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.domain_cert.arn
    ssl_support_method = "sni-only"
  }
}