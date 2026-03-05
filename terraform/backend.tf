terraform {
  backend "s3" {
    bucket       = "decenter-sre-task-terraform-state"
    key          = "decenter-sre-task/terraform.tfstate"
    use_lockfile = true
    region       = "eu-central-1"
    encrypt      = true
  }
}
