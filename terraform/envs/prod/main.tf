locals {
  service_name = "log-analyzer"
  environment  = "prod"
  base_tags = {
    Project = "log-analyzer"
  }

  log_analyzer_port = 8080
}

module "network" {
  source      = "../../modules/network"
  name        = local.service_name
  environment = local.environment
  aws_region  = var.aws_region
  tags        = local.base_tags
}

module "ecr" {
  source      = "../../modules/ecr"
  name        = local.service_name
  environment = local.environment
  tags        = local.base_tags
  repository_name = local.service_name
}

module "iam" {
  source              = "../../modules/iam"
  name                = local.service_name
  environment         = local.environment
  service_name        = local.service_name
  attach_s3_read      = true
  allowed_s3_buckets  = ["devops-assignment-logs-430957"]
  task_role_name      = "log-analyzer-ecs-task-role"
  execution_role_name = "log-analyzer-ecs-task-execution-role"
  s3_policy_name      = "log-analyzer-s3-access-policy"
  tags                = local.base_tags
}

module "alb" {
  source             = "../../modules/alb"
  name               = local.service_name
  environment        = local.environment
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  certificate_arn    = data.aws_acm_certificate.cert.arn
  target_port        = local.log_analyzer_port
  health_check_path  = "/healthz"
  alb_name           = "log-analyzer-alb"
  target_group_name  = "log-analyzer-tg"
  security_group_name = "log-analyzer-alb-sg"
  tags               = local.base_tags
}

module "ecs_service" {
  source                 = "../../modules/ecs_service"
  name                   = local.service_name
  environment            = local.environment
  service_name           = local.service_name
  cluster_name           = "${local.service_name}-cluster"
  ecs_service_name       = "${local.service_name}-service"
  task_definition_family = "${local.service_name}-task"
  log_group_name         = "/ecs/${local.service_name}"
  container_image        = "${module.ecr.repository_url}:${var.image_tag}"
  container_port         = local.log_analyzer_port
  task_role_arn          = module.iam.task_role_arn
  execution_role_arn     = module.iam.execution_role_arn
  subnet_ids             = module.network.private_subnet_ids
  vpc_id                 = module.network.vpc_id
  alb_security_group_id  = module.alb.alb_security_group_id
  desired_count          = 1
  target_group_arn       = module.alb.target_group_arn
  tags                   = local.base_tags
}

module "cloudfront" {
  source                       = "../../modules/cloudfront"
  name                         = local.service_name
  environment                  = local.environment
  origin_domain_name           = var.origin_hostname != "" ? var.origin_hostname : module.alb.alb_dns_name
  custom_origin_header_name    = "X-Origin-Verify"
  custom_origin_header_value   = jsondecode(data.aws_secretsmanager_secret_version.origin_verify.secret_string)["OriginVerifyHeader"]
  comment                      = "Distribution for log-analyzer"
  waf_name                     = "log-analyzer-waf"
  tags                         = local.base_tags
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}
