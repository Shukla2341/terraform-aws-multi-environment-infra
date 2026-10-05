terraform {
  backend "s3" {
    bucket       = "general23buucket"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
