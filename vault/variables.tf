variable "cluster_size" {
  description = "The size of the vault cluster."
  default = 2
}

variable "domain" {}

variable "datacenter" {}

variable "os_image" {}

variable "consul_master_token" {}

variable "consul_server" {}

variable "consul_gossip_password" {}

variable "consul_cluster_servers" {}

variable "consul_ca_cert_pem" {}

variable "consul_private_key_algorithm" {}

variable "consul_private_key_pem" {}
