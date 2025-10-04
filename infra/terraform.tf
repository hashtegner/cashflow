terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  backend "s3" {
    bucket = "cashflow-tf-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
  }

  required_version = "~> 1.13"
}
