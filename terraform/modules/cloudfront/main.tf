locals {
  sanitized_name  = replace(lower(var.name), "/[^a-z0-9-]/", "-")
  resource_prefix = "${local.sanitized_name}-${var.environment}"
  origin_id       = "${local.resource_prefix}-origin"

  common_tags = merge(
    {
      Name        = local.resource_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_wafv2_web_acl" "this" {
  provider = aws.us-east-1
  name     = "${local.resource_prefix}-waf"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-Managed-Rules-Common-Rule-Set"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.sanitized_name}-aws-managed-rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.sanitized_name}-waf"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}

resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name = var.origin_domain_name
    origin_id   = local.origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = var.origin_protocol_policy
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    dynamic "origin_custom_header" {
      for_each = var.custom_origin_header_name == null ? [] : [var.custom_origin_header_name]
      content {
        name  = var.custom_origin_header_name
        value = var.custom_origin_header_value
      }
    }
  }

  enabled         = true
  is_ipv6_enabled = true
  comment         = "Distribution for ${local.resource_prefix}"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = aws_wafv2_web_acl.this.arn

  tags = local.common_tags
}
