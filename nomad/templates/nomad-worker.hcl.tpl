datacenter           = "${datacenter}"
bind_addr            ="${node_name}"
disable_update_check = true
enable_syslog        = true
log_level            = "INFO"
log_file             = "/opt/nomad/data/"
name                 = "${node_name}"
region               = "europe"

client {
  enabled = true
  bridge_network_name = "nomad"
}

tls {
  http = true
  rpc  = true

  ca_file   = "/opt/nomad/config/nomad-ca.pem"
  cert_file = "/opt/nomad/config/${node_name}.crt"
  key_file  = "/opt/nomad/config/${node_name}.key"

  verify_server_hostname = true
  verify_https_client    = true
}

vault {
  enabled   = true
  address   = "https://active.${datacenter}-vault-cluster.service.consul:8200"
  ca_file   = "/opt/vault/config/vault-ca.pem"
  cert_file = "/opt/vault/config/${node_name}.crt"
  key_file  = "/opt/vault/config/${node_name}.key"
}

acl {
  enabled = true
}

autopilot {
    cleanup_dead_servers      = true
    enable_redundancy_zones   = false
    disable_upgrade_migration = false
    enable_custom_upgrades    = false
}

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}

consul {
  address                = "127.0.0.1:8501"
  auto_advertise         = true
  server_service_name    = "${datacenter}-nomad-cluster"
  client_service_name    = "${datacenter}-nomad-cluster-worker"
  client_http_check_name = "Nomad Worker HTTP Check"
  client_auto_join       = true
  ssl                    = true
  ca_file                = "/opt/consul/config/consul-ca.pem"
  cert_file              = "/opt/consul/config/${node_name}.crt"
  key_file               = "/opt/consul/config/${node_name}.key"
}
