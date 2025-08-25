
resource "random_id" "suffix" {
  byte_length = 8
  keepers = {
    project_name = var.project_name
  }
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

# WordPress admin password generation
resource "random_password" "wp_admin_password" {
  length  = 20
  special = false
}
