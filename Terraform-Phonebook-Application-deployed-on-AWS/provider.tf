terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  #   access_key = ""
  #   secret_key = ""
}
# Configure the GitHub Provider
provider "github" {
  token = "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"
}