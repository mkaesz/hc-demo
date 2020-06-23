output "consul_ca_cert_pem" {
  value = tls_self_signed_cert.consul_ca.cert_pem
}

output "consul_cli_cert_pem" {
  value = tls_locally_signed_cert.consul_cli.cert_pem
}

output "consul_cli_private_key_pem" {
  value = tls_private_key.consul.private_key_pem
} 

output "consul_master_token" {
  value = random_uuid.consul_master_token.result
}

output "consul_gossip_password" {
  value = random_string.consul_gossip_password.result
}

output "consul_cluster_servers" {
  value = local.consul_cluster_servers_expanded
}

output "consul_private_key_algorithm" {
  value = tls_private_key.consul_ca.algorithm
}

output "consul_private_key_pem" {
  value = tls_private_key.consul_ca.private_key_pem
}
