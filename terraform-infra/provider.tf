terraform {
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

