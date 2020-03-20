locals {
  # task_prefix  = var.project.pr == "" ? "" : "${var.project.pr}-"
  prefix     = var.project.prefix
  api_domain = "api.${var.domain}"
  # admin_domain = "admin.${var.domain}"
}

resource "random_string" "rails_secret_key_base" {
  length  = 128
  special = false
}

resource "random_string" "jwt_secret" {
  length  = 128
  special = false
}

resource "random_string" "db_password" {
  length  = 32
  special = false
}

resource "aws_iam_user" "user" {
  name = "${local.prefix}-rails"
  tags = var.project.tags
}

resource "aws_iam_access_key" "key" {
  user = aws_iam_user.user.name
}

data "aws_region" "current" {}

locals {
  aws_region     = data.aws_region.current.name
  aws_access_key = aws_iam_access_key.key.id
  aws_secret_key = aws_iam_access_key.key.secret

  db_name     = replace(local.prefix, "-", "_")
  db_user     = local.db_name
  db_password = random_string.db_password.result
  db_url      = "postgres://${local.db_user}:${local.db_password}@${var.db.host}:${var.db.port}/${local.db_name}"

  # redis_db_map = {
  #   production  = 0
  #   development = 0
  #   staging     = 1
  #   preview     = 2
  # }
  #redis_url = var.cache.url

  rails_environment = {
    AWS_ACCESS_KEY           = local.aws_access_key
    AWS_REGION               = local.aws_region
    AWS_SECRET_KEY           = local.aws_secret_key
    DATABASE_URL             = local.db_url
    JWT_SECRET_KEY           = random_string.jwt_secret.result
    RACK_ENV                 = "production"
    RAILS_ENV                = "production"
    RAILS_LOG_TO_STDOUT      = "enabled"
    RAILS_NOCOLOR            = "enabled"
    RAILS_SERVE_STATIC_FILES = "enabled"
    # REDIS_URL                = local.redis_url
    SECRET_KEY_BASE = random_string.rails_secret_key_base.result
    # SMTP_HOST                = var.smtp_host
    # SMTP_PASSWORD            = local.ses_password
    # SMTP_USERNAME            = local.aws_access_key

    # AIRBRAKE_API_KEY=
    # AIRBRAKE_PROJECT_ID=
    # APP_ROLE=web
    # DB_HOST=
    # DB_NAME=lunchiatto
    # DB_PASSWORD=
    # DB_PORT=5432
    # DB_USER=lunchiatto
    # GOOGLE_KEY=
    # GOOGLE_SECRET=
    # PAPERTRAIL_HOST=
    # PAPERTRAIL_PORT=
    # SENDGRID_PASSWORD=
    # SENDGRID_USERNAME=
  }
}

# one-off task runner, eg. migrations, rake tasks
module "runner_task" {
  source = "github.com/codequest-eu/terraform-modules?ref=d8639a1//ecs/task"
  create = true

  project               = var.project.name
  environment           = var.project.environment
  task                  = "${local.prefix}runner"
  container             = "rails"
  image                 = var.image
  entry_point           = ["bundle", "exec", "rails"]
  command               = ["help"]
  environment_variables = local.rails_environment
  memory_soft_limit     = 128
  memory_hard_limit     = 2048
}

# HTTP api
module "api_task" {
  source                = "github.com/codequest-eu/terraform-modules?ref=d8639a1//ecs/task"
  create                = true
  project               = var.project.name
  environment           = var.project.environment
  task                  = "${local.prefix}api"
  container             = "api"
  image                 = var.image
  command               = ["rails", "server"]
  ports                 = [3000]
  environment_variables = local.rails_environment
  memory_soft_limit     = var.project.environment == "production" ? 512 : 128
  memory_hard_limit     = 2048
}

# module "api_domain" {
#   source = "github.com/codequest-eu/terraform-modules?ref=d8639a1//ecs/network/domain"
#   create = var.create

#   name              = local.api_domain
#   zone_id           = var.hosted_zone_id
#   load_balancer_arn = var.cluster.load_balancer_arn
#   https             = false # we're manually assigning a wildcard certificate
#   tags              = var.project.tags
# }

module "api_service" {
  source = "github.com/codequest-eu/terraform-modules?ref=d8639a1//ecs/services/web"
  create = true

  name                   = "${local.prefix}-api"
  target_group_name      = "${local.prefix}-api"
  container              = "api"
  container_port         = 3000
  cluster_arn            = var.cluster.arn
  task_definition_arn    = module.api_task.arn
  desired_count          = var.project.environment == "production" ? 2 : 1
  deployment_min_percent = var.project.environment == "production" ? 50 : 0

  vpc_id       = var.cluster.vpc_id
  listener_arn = var.cluster.https_listener_arn
  role_arn     = var.cluster.web_service_role_arn
  rule_domain  = local.api_domain
}

# # sidekiq background worker
# module "worker_task" {
#   source = "github.com/codequest-eu/terraform-modules?ref=d8639a1//ecs/task"
#   create = var.create

#   project               = var.project.name
#   environment           = var.project.environment
#   task                  = "${local.task_prefix}worker"
#   container             = "worker"
#   image                 = var.image
#   command               = ["sidekiq", "-c", "5", "-v", "-q", "default", "-q", "mailers"]
#   environment_variables = local.rails_environment
#   memory_soft_limit     = var.project.environment == "production" ? 512 : 128
#   memory_hard_limit     = 2048
# }

# module "worker_service" {
#   source = "github.com/codequest-eu/terraform-modules?ref=d8639a1//ecs/services/worker"
#   create = var.create

#   name                   = "${local.prefix}-worker"
#   cluster_arn            = var.cluster.arn
#   task_definition_arn    = module.worker_task.arn
#   desired_count          = var.project.environment == "production" ? 2 : 1
#   deployment_min_percent = var.project.environment == "production" ? 50 : 0
# }

# resource "null_resource" "db_create" {
#   provisioner "local-exec" {
#     environment = {
#       CREATE_DB_PAYLOAD = jsonencode({
#         db = {
#           host = var.db.host
#           port = var.db.port
#         }
#         master = {
#           db       = var.db.master_db
#           user     = var.db.master_username
#           password = var.db.master_password
#         }
#         environment = {
#           db       = local.db_name
#           user     = local.db_user
#           password = local.db_password
#         }
#       })
#     }

#     command = join(" ", [
#       "aws lambda invoke",
#       "--region", data.aws_region.current.name,
#       "--function-name '${var.db.create_db_lambda_arn}'",
#       "--payload $CREATE_DB_PAYLOAD",
#       "/dev/null"
#     ])
#   }

#   provisioner "local-exec" {
#     when = destroy

#     environment = {
#       DROP_DB_PAYLOAD = jsonencode({
#         db = {
#           host = var.db.host
#           port = var.db.port
#         }
#         master = {
#           db       = var.db.master_db
#           user     = var.db.master_username
#           password = var.db.master_password
#         }
#         environment = {
#           user = local.db_user
#           db   = local.db_name
#         }
#       })
#     }

#     command = var.project.environment != "production" ? join(" ", [
#       "aws lambda invoke",
#       "--region", local.aws_region,
#       "--function-name '${var.db.drop_db_lambda_arn}'",
#       "--payload $DROP_DB_PAYLOAD",
#       "/dev/null"
#     ]) : "echo 'Tried to drop the production database!'"
#   }
# }

# resource "null_resource" "db_migrate" {
#   depends_on = [null_resource.db_create]

#   triggers = {
#     runner_arn = module.runner_task.arn
#   }

#   provisioner "local-exec" {
#     command = join(" ", [
#       "aws ecs run-task",
#       "--region", local.aws_region,
#       "--cluster", var.cluster.arn,
#       "--task-definition", module.runner_task.arn,
#       "--overrides '${jsonencode({
#         containerOverrides = [{
#           name    = "rails",
#           command = ["db:migrate"],
#         }]
#       })}'"
#     ])
#   }
# }
