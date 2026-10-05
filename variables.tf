variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "multi-env"
}

variable "instance_types" {
  description = "EC2 instance type for each environment"
  type        = map(string)

  default = {
    dev     = "t3.micro"
    staging = "t3.micro"
    prod    = "t3.small"
  }
}
