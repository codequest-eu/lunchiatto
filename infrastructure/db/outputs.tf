output "host" {
  value = module.db.host
}

output "port" {
  value = module.db.port
}

output "master_db" {
  value = module.db.db
}

output "master_username" {
  value = module.db.username
}

output "master_password" {
  value = module.db.password
}

output "master_url" {
  value = module.db.url
}

output "create_db_lambda_arn" {
  value = module.lambdas.create_arn
}

output "drop_db_lambda_arn" {
  value = module.lambdas.drop_arn
}
