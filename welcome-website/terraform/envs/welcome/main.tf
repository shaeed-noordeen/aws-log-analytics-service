locals {
  service_name    = "welcome-web"
  environment     = "welcome"
  container_port  = 80
  base_tags = {
    Project = "welcome-web"
  }
}

module "network" {
  source      = "../../../terraform_modules/network"
  name        = local.service_name
  environment = local.environment
  aws_region  = var.aws_region
  tags        = local.base_tags
}

module "ecr" {
  source          = "../../../terraform_modules/ecr"
  name            = local.service_name
  environment     = local.environment
  repository_name = local.service_name
  tags            = local.base_tags
}

module "iam" {
  source              = "../../../terraform_modules/iam"
  name                = local.service_name
  environment         = local.environment
  service_name        = local.service_name
  task_role_name      = "welcome-web-ecs-task-role"
  execution_role_name = "welcome-web-ecs-task-execution-role"
  tags                = local.base_tags
}

module "alb" {
  source              = "../../../terraform_modules/alb"
  name                = local.service_name
  environment         = local.environment
  vpc_id              = module.network.vpc_id
  public_subnet_ids   = module.network.public_subnet_ids
  certificate_arn     = data.aws_acm_certificate.alb_cert.arn
  target_port         = local.container_port
  health_check_path   = "/"
  alb_name            = "welcome-web-alb"
  target_group_name   = "welcome-web-tg"
  security_group_name = "welcome-web-alb-sg"
  tags                = local.base_tags
}

module "ecs_service" {
  source                 = "../../../terraform_modules/ecs_service"
  name                   = local.service_name
  environment            = local.environment
  service_name           = local.service_name
  cluster_name           = "${local.service_name}-cluster"
  ecs_service_name       = "${local.service_name}-service"
  task_definition_family = "${local.service_name}-task"
  log_group_name         = "/ecs/${local.service_name}"
  container_image        = "${module.ecr.repository_url}:${var.image_tag}"
  container_port         = local.container_port
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
  source                 = "../../../terraform_modules/cloudfront"
  name                   = local.service_name
  environment            = local.environment
  origin_domain_name     = var.origin_hostname != "" ? var.origin_hostname : module.alb.alb_dns_name
  origin_protocol_policy = "https-only"
  comment                = "Distribution for welcome-web"
  tags                   = local.base_tags
  ordered_cache_behaviors = []
  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}
