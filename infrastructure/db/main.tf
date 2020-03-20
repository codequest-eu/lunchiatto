module "master_credentials" {
  source = "./random_credentials"
  create = var.create
}

module "db" {
  source = "github.com/codequest-eu/terraform-modules?ref=d8639a1//rds/postgres"
  create = var.create

  project     = var.project.name
  environment = var.project.environment
  tags        = var.project.tags

  vpc_id     = var.cluster.vpc_id
  subnet_ids = var.cluster.private_subnet_ids
  security_group_ids = [
    var.cluster.hosts_security_group_id,
    module.lambdas.security_group_id,
  ]

  instance_type   = var.project.environment == "production" ? "db.t3.small" : "db.t3.micro"
  storage         = var.project.environment == "production" ? 60 : 20
  multi_az        = var.project.environment == "production"
  prevent_destroy = var.project.environment == "production"

  db       = replace(var.project.name, "-", "_")
  username = module.master_credentials.username
  password = module.master_credentials.password
}

module "lambdas" {
  source = "./lambdas"
  create = var.create

  project = var.project
  cluster = var.cluster
}
