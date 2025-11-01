# CloudFront Module

Provisions a CloudFront distribution backed by a custom origin, with optional custom header authentication and an attached AWS Managed WAF ACL (using the `aws.us-east-1` provider alias).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Base name for resources (service name). | `string` | n/a | yes |
| `environment` | Environment name, e.g. `dev`/`stage`/`prod`. | `string` | `"prod"` | no |
| `tags` | Extra tags to apply to all resources. | `map(string)` | `{}` | no |
| `origin_domain_name` | Domain name of the origin (ALB, custom host, etc.). | `string` | n/a | yes |
| `origin_protocol_policy` | Protocol policy CloudFront uses to reach the origin. | `string` | `"https-only"` | no |
| `custom_origin_header_name` | Optional header name to send to the origin. Provide together with the value. | `string` | `null` | no |
| `custom_origin_header_value` | Optional header value to send to the origin. Provide together with the name. | `string` | `null` | no |
| `origin_id` | Identifier to use for the origin inside the distribution. | `string` | `"alb-origin"` | no |
| `comment` | Distribution comment field. | `string` | `null` | no |
| `default_root_object` | Default root object served by CloudFront. | `string` | `"index.html"` | no |
| `waf_name` | WAF ACL name (defaults to `<name>-waf`). | `string` | `null` | no |
| `ordered_cache_behaviors` | Ordered cache behaviors (path pattern, TTLs, forwarding modes). | `list(object)` | see module for default | no |

## Outputs

| Name | Description |
|------|-------------|
| `cloudfront_domain_name` | Public domain name of the CloudFront distribution. |

## Notes

- This module expects the `aws.us-east-1` provider alias to be passed in so the WAF ACL can be created in the required region. Example:

  ```hcl
  module "cloudfront" {
    source = "../../modules/cloudfront"
    providers = {
      aws.us-east-1 = aws.us-east-1
    }
    # ...
  }
  ```
