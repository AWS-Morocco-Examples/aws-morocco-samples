terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#----------------------------------------
# Providers
#----------------------------------------
provider "aws" {
  alias  = "provider"
  region = "us-east-1"
}

provider "aws" {
  alias  = "consumer"
  region = "eu-west-1"
}