terraform {
  required_version = ">= 0.13.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.1.0"
    }
  }
}
