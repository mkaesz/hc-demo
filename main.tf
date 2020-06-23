provider "libvirt" {
  uri                              = "qemu+ssh://root@192.168.0.171/system"
}

module "bastion" {
  source                           = "./bastion"

  datacenter                       = var.datacenter
  domain                           = var.domain
  os_image                         = var.os_image
  consul_ca_cert_pem               = module.consul_cluster.consul_ca_cert_pem
  vault_ca_cert_pem                = module.vault_cluster.vault_ca_cert_pem
  nomad_ca_cert_pem                = module.nomad_cluster.nomad_ca_cert_pem
  consul_cli_private_key_pem       = module.consul_cluster.consul_cli_private_key_pem
  vault_cli_private_key_pem        = module.vault_cluster.vault_cli_private_key_pem
  nomad_cli_private_key_pem        = module.nomad_cluster.nomad_cli_private_key_pem
  consul_cli_cert_pem              = module.consul_cluster.consul_cli_cert_pem
  vault_cli_cert_pem               = module.vault_cluster.vault_cli_cert_pem
  nomad_cli_cert_pem               = module.nomad_cluster.nomad_cli_cert_pem
  consul_master_token              = module.consul_cluster.consul_master_token
}

module "consul_cluster" {
  source                           = "./consul"

  datacenter                       = var.datacenter
  domain                           = var.domain
  os_image                         = var.os_image
  consul_server                    = "dc1-server-consul-0.msk.local:8500"
}

module "vault_cluster" {
  source                           = "./vault"

  datacenter                       = var.datacenter
  domain                           = var.domain
  os_image                         = var.os_image
  consul_server                    = "dc1-server-consul-0.msk.local:8500"
  consul_gossip_password           = module.consul_cluster.consul_gossip_password 
  consul_master_token              = module.consul_cluster.consul_master_token
  consul_cluster_servers           = module.consul_cluster.consul_cluster_servers
  consul_ca_cert_pem               = module.consul_cluster.consul_ca_cert_pem
  consul_private_key_pem           = module.consul_cluster.consul_private_key_pem
  consul_private_key_algorithm     = module.consul_cluster.consul_private_key_algorithm
}

module "nomad_cluster" {
  source                           = "./nomad"

  datacenter                       = var.datacenter
  domain                           = var.domain
  os_image                         = var.os_image
  consul_server                    = "dc1-server-consul-0.msk.local:8500"
  consul_gossip_password           = module.consul_cluster.consul_gossip_password 
  consul_master_token              = module.consul_cluster.consul_master_token
  consul_cluster_servers           = module.consul_cluster.consul_cluster_servers
  consul_ca_cert_pem               = module.consul_cluster.consul_ca_cert_pem
  consul_private_key_pem           = module.consul_cluster.consul_private_key_pem 
  consul_private_key_algorithm     = module.consul_cluster.consul_private_key_algorithm
  vault_ca_cert_pem                = module.vault_cluster.vault_ca_cert_pem
  vault_private_key_pem            = module.vault_cluster.vault_private_key_pem
  vault_private_key_algorithm      = module.vault_cluster.vault_private_key_algorithm
}
