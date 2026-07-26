terraform {
  required_version = "~> 1.0"
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "shikanime-studio"
    workspaces {
      prefix = "shikanime-google-cloud-"
    }
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.36"
    }
  }
}