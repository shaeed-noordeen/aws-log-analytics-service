data "aws_acm_certificate" "cert" {
  domain   = "*.shaeed.co.uk"
  statuses = ["ISSUED"]
}

data "aws_secretsmanager_secret" "origin_verify" {
  arn = "arn:aws:secretsmanager:eu-north-1:982890094160:secret:prod/alb/verify-5bl93U"
}

data "aws_secretsmanager_secret_version" "origin_verify" {
  secret_id = data.aws_secretsmanager_secret.origin_verify.id
}
