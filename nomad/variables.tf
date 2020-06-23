variable "cluster_size" {
  default = 3
}

variable "workers" {
  default = 2
}

variable "domain" {}

variable "datacenter" {}

variable "os_image" {}

variable "consul_gossip_password" {}

variable "consul_master_token" {}

variable "consul_server" {}

variable "consul_cluster_servers" {}

variable "consul_ca_cert_pem" {}

variable "consul_private_key_algorithm" {}

variable "consul_private_key_pem" {}

variable "vault_ca_cert_pem" {}

variable "vault_private_key_algorithm" {}

variable "vault_private_key_pem" {}
