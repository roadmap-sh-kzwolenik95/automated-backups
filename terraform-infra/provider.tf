terraform {
  cloud {
    organization = "roadmap-sh"
    hostname     = "app.terraform.io"

    workspaces {
      name = "automated-backups"
    }
  }
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.49.1"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}
