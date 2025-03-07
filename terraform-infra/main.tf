data "digitalocean_images" "available" {
  filter {
    key    = "distribution"
    values = ["Ubuntu"]
  }
  filter {
    key    = "regions"
    values = ["fra1"]
  }
  filter {
    key      = "name"
    values   = ["LTS"]
    match_by = "substring"
  }
  filter {
    key    = "type"
    values = ["base"]
  }
  sort {
    key       = "name"
    direction = "desc"
  }
}

data "digitalocean_ssh_key" "terraform" {
  name = var.ssh_key_name
}

resource "digitalocean_droplet" "ubuntu" {
  image  = data.digitalocean_images.available.images[0].slug
  name   = var.name
  region = var.region
  size   = var.size
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]
  tags = ["roadmapsh-ab"]
}

resource "digitalocean_spaces_bucket" "sos" {
  name   = "backups-roadmapsh-kzwolenik95"
  region = "fra1"
}
