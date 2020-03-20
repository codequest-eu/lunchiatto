variable "create" {
  type    = bool
  default = true
}

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
    vpc_id                  = string
    private_subnet_ids      = list(string)
    hosts_security_group_id = string
  })
}
