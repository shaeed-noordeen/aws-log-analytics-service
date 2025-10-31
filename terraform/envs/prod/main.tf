module "network" {
  source       = "../../modules/network"
  project_name = "log-analyzer"
  aws_region   = var.aws_region
  tags = {
    Environment = "prod"
    Project     = "log-analyzer"
  }
}

module "ecr" {
  source          = "../../modules/ecr"
  repository_name = "log-analyzer"
  tags = {
    Environment = "prod"
    Project     = "log-analyzer"
  }
}

module "iam" {
  source           = "../../modules/iam"
  project_name     = "log-analyzer"
  logs_bucket_name = "devops-assignment-logs-430957"
  tags = {
    Environment = "prod"
    Project     = "log-analyzer"
  }
}

module "alb" {
  source                     = "../../modules/alb"
  project_name               = "log-analyzer"
  vpc_id                     = module.network.vpc_id
  public_subnet_ids          = module.network.public_subnet_ids
  certificate_arn            = data.aws_acm_certificate.cert.arn
  origin_verify_header_value = jsondecode(data.aws_secretsmanager_secret_version.origin_verify.secret_string)["OriginVerifyHeader"]
  tags = {
    Environment = "prod"
    Project     = "log-analyzer"
  }
}

module "ecs_service" {
  source                  = "../../modules/ecs_service"
  project_name            = "log-analyzer"
  vpc_id                  = module.network.vpc_id
  private_subnet_ids      = module.network.private_subnet_ids
  alb_security_group_id   = module.alb.alb_security_group_id
  target_group_arn        = module.alb.target_group_arn
  alb_listener            = module.alb.listener
  task_execution_role_arn = module.iam.task_execution_role_arn
  task_role_arn           = module.iam.task_role_arn
  image                   = "${module.ecr.repository_url}:${var.image_tag}"
  aws_region              = var.aws_region
  tags = {
    Environment = "prod"
    Project     = "log-analyzer"
  }
}

module "cloudfront" {
  source                     = "../../modules/cloudfront"
  project_name               = "log-analyzer"
  alb_dns_name               = module.alb.alb_dns_name
  origin_hostname            = var.origin_hostname
  origin_verify_header_value = jsondecode(data.aws_secretsmanager_secret_version.origin_verify.secret_string)["OriginVerifyHeader"]
  tags = {
    Environment = "prod"
    Project     = "log-analyzer"
  }
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}
