# username has to start with a letter
resource "random_string" "username_first_letter" {
  count = var.create ? 1 : 0

  length  = 1
  number  = false
  special = false
}

resource "random_string" "username_rest" {
  count = var.create ? 1 : 0

  length  = 7
  special = false
}

resource "random_string" "password" {
  count = var.create ? 1 : 0

  length  = 32
  special = false
}

locals {
  username = var.create ? "${random_string.username_first_letter[0].result}${random_string.username_rest[0].result}" : ""
  password = var.create ? random_string.password[0].result : ""
}
