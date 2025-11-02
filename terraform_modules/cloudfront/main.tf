locals {
  sanitized_name = replace(lower(var.name), "/[^a-z0-9-]/", "-")

  base_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  waf_name        = coalesce(var.waf_name, "${local.sanitized_name}-waf")
  distribution_comment = coalesce(var.comment, "Distribution for ${var.name}")
}

resource "aws_wafv2_web_acl" "main" {
  provider = aws.us-east-1
  name     = local.waf_name
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
      metric_name                = "aws-managed-rules-common-rule-set"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-metrics"
    sampled_requests_enabled   = true
  }

  tags = merge(
    local.base_tags,
    {
      Name = local.waf_name
    }
  )
}

resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name = var.origin_domain_name
    origin_id   = var.origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = var.origin_protocol_policy
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    dynamic "custom_header" {
      for_each = var.custom_origin_header_name == null ? [] : [var.custom_origin_header_name]
      content {
        name  = var.custom_origin_header_name
        value = var.custom_origin_header_value
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = local.distribution_comment
  default_root_object = var.default_root_object

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.origin_id

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

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern     = ordered_cache_behavior.value.path_pattern
      allowed_methods  = ordered_cache_behavior.value.allowed_methods
      cached_methods   = ordered_cache_behavior.value.cached_methods
      target_origin_id = var.origin_id

      forwarded_values {
        query_string = ordered_cache_behavior.value.forward_query_string
        cookies {
          forward = ordered_cache_behavior.value.forward_cookies
        }
      }

      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
      min_ttl                = ordered_cache_behavior.value.min_ttl
      default_ttl            = ordered_cache_behavior.value.default_ttl
      max_ttl                = ordered_cache_behavior.value.max_ttl
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = aws_wafv2_web_acl.main.arn

  tags = local.base_tags
}
