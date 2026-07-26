terraform {
  required_version = "~> 1.8"
  cloud {
    hostname     = "app.terraform.io"
    organization = "shikanime-studio"
    workspaces {
      name = "shikanime-github"
    }
  }
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.4"
    }
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.43"
    }
  }
}

provider "github" {}
