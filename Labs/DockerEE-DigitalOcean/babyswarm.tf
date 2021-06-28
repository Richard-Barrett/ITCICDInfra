variable "do_token" {}

variable "ssh_keys" {
  default = []
}

variable "do_image" {
}

variable "domain_name" {
}

variable "swarm-prefix" {
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_tag" "managers" {
  name = "managers"
}

resource "digitalocean_tag" "workers" {
  name = "workers"
}

# Create swarm manager and workers
resource "digitalocean_droplet" "swarm-manager" {
  image    = "${var.do_image}"
  name     = "${var.swarm-prefix}-manager"
  region   = "nyc3"
  size     = "s-4vcpu-8gb"
  ssh_keys = "${var.ssh_keys}"
  tags     = ["${digitalocean_tag.managers.id}"]
}

resource "digitalocean_droplet" "swarm-worker1" {
  image    = "${var.do_image}"
  name     = "${var.swarm-prefix}-worker1"
  region   = "nyc3"
  size     = "s-4vcpu-8gb"
  ssh_keys = "${var.ssh_keys}"
  tags     = ["${digitalocean_tag.workers.id}"]
}

resource "digitalocean_droplet" "swarm-worker2" {
  image    = "${var.do_image}"
  name     = "${var.swarm-prefix}-worker2"
  region   = "nyc3"
  size     = "s-4vcpu-8gb"
  ssh_keys = "${var.ssh_keys}"
  tags     = ["${digitalocean_tag.workers.id}"]
}

resource "digitalocean_floating_ip" "swarm-manager" {
  droplet_id = "${digitalocean_droplet.swarm-manager.id}"
  region     = "${digitalocean_droplet.swarm-manager.region}"
}

resource "digitalocean_domain" "swarm-domain" {
  name       = "${var.domain_name}"
}

# Add a record to the domain
resource "digitalocean_record" "swarm-worker1" {
  domain = "${digitalocean_domain.swarm-domain.name}"
  name   = "${var.swarm-prefix}-worker1"
  type   = "A"
  value  = "${digitalocean_droplet.swarm-worker1.ipv4_address}"
}

# Add a record to the domain
resource "digitalocean_record" "swarm-worker2" {
  domain = "${digitalocean_domain.swarm-domain.name}"
  name   = "${var.swarm-prefix}-worker2"
  type   = "A"
  value  = "${digitalocean_droplet.swarm-worker2.ipv4_address}"
}

# Add a record to the domain
resource "digitalocean_record" "swarm-manager" {
  domain = "${digitalocean_domain.swarm-domain.name}"
  type   = "A"
  name   = "${var.swarm-prefix}-manager"
  value  = "${digitalocean_droplet.swarm-manager.ipv4_address}"
}

# Add a record to the domain
resource "digitalocean_record" "ucp" {
  domain = "${digitalocean_domain.swarm-domain.name}"
  type   = "A"
  name   = "ucp"
  value  = "${digitalocean_droplet.swarm-manager.ipv4_address}"
}

output "ip address swarm manager" {
  value = "${digitalocean_droplet.swarm-manager.ipv4_address}"
}

output "floating ip address swarm manager" {
  value = "${digitalocean_floating_ip.swarm-manager.ip_address}"
}
