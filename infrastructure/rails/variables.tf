# variable "create" {
#   type    = bool
#   default = true
# }

variable "project" {
  description = "Project info"
  type = object({
    name        = string
    environment = string
    prefix      = string
    tags        = map(string)
  })
}

variable "cluster" {
  description = "Cluster info"
  type = object({
    arn                  = string
    vpc_id               = string
    load_balancer_arn    = string
    https_listener_arn   = string
    web_service_role_arn = string
  })
}

variable "db" {
  description = "Postgres info"
  type = object({
    host                 = string
    port                 = number
    master_db            = string
    master_username      = string
    master_password      = string
    create_db_lambda_arn = string
    drop_db_lambda_arn   = string
  })
}

# variable "cache" {
#   description = "Redis info"
#   type = object({
#     url = string
#   })
# }

variable "domain" {
  type = string
}

# variable "hosted_zone_id" {
#   type = string
# }

variable "image" {
  description = "Rails app docker image to use"
  type        = string
}

# variable "smtp_host" {
#   type = string
# }

# variable "policy_arns" {
#   type = map(string)
# }

# variable "frontend_domain" {
#   type = string
# }
