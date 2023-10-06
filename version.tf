terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.28.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token # Digital Ocean token
}