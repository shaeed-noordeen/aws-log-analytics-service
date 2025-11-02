data "aws_acm_certificate" "alb_cert" {
  domain   = "*.shaeed.co.uk"
  statuses = ["ISSUED"]
}
