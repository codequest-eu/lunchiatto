locals {
  project           = "lunchiatto"
  environment       = "development"
  rails_environment = {}
  project_info = {
    name        = "lunchiatto"
    environment = "production"
    prefix      = "lunchiatto"
    tags        = {}
  }
}

module "cluster" {
  source = "github.com/codequest-eu/terraform-modules?ref=d8639a1//ecs"

  project       = local.project
  project_index = 0
  environment   = local.environment
  tags = {
    Project     = local.project,
    Environment = local.environment
  }

  availability_zones_count = 2
  nat_instance             = true
  nat_instance_type        = "t3a.nano"
}

module "hosts" {
  source = "github.com/codequest-eu/terraform-modules?ref=d8639a1//ecs/host_group"

  name        = "hosts"
  project     = local.project
  environment = local.environment

  instance_type = "t3a.micro"
  size          = 1
  # size          = var.project.environment == "production" ? 2 : 1


  instance_profile  = module.cluster.host_profile_name
  subnet_ids        = module.cluster.private_subnet_ids
  security_group_id = module.cluster.hosts_security_group_id
  cluster_name      = module.cluster.name
  bastion_key_name  = module.cluster.bastion_key_name
}

module "rails_image_repository" {
  source = "github.com/codequest-eu/terraform-modules?ref=d8639a1//ecs/repository"
  create = true

  project    = local.project
  image_name = "lunchiatto"
  tags = {
    Project     = local.project,
    Environment = local.environment
  }
}

# module "api_task" {
#   source    = "github.com/codequest-eu/terraform-modules?ref=d8639a1//ecs/task"
#   create    = true
#   image_tag = "latest"


#   project     = local.project
#   environment = local.environment
#   # task                  = "${local.task_prefix}api"
#   task                  = "api"
#   container             = "api"
#   image                 = "${module.rails_image_repository.url}:latest"
#   command               = ["rails", "server"]
#   ports                 = [3000]
#   environment_variables = local.rails_environment
#   memory_soft_limit     = 128
#   memory_hard_limit     = 2048
# }

module "db" {
  source = "./db"
  create = true

  project = local.project_info
  cluster = module.cluster
}

module "rails" {
  source = "./rails"
  #create = true

  project = local.project_info
  domain  = module.cluster.load_balancer_domain
  # hosted_zone_id = var.hosted_zone_id
  cluster = module.cluster
  db      = module.db
  # cache          = local.cache
  image = "${module.rails_image_repository.url}:latest"
  # smtp_host      = var.smtp_host
  # policy_arns    = var.rails_policy_arns
}
