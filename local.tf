locals {
  environment = terraform.workspace

  instance_type = var.instance_types[terraform.workspace]

  name_prefix = "${var.project_name}-${local.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
  }
}
