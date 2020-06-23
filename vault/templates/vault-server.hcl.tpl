storage "consul" {
  address = "127.0.0.1:8501"
  scheme = "https"
  service = "${datacenter}-vault-cluster"
  path = "vault/"
  token      = "${consul_default_token}"
  tls_ca_file = "/opt/consul/config/consul-ca.pem"
  tls_cert_file = "/opt/consul/config/${node_name}.crt"
  tls_key_file = "/opt/consul/config/${node_name}.key"
}

service_registration "consul" {
  scheme        = "https"
  address = "127.0.0.1:8501"
  service = "${datacenter}-vault-cluster"
  tls_ca_file = "/opt/consul/config/consul-ca.pem"
  tls_cert_file = "/opt/consul/config/${node_name}.crt"
  tls_key_file = "/opt/consul/config/${node_name}.key"
  token      = "${consul_default_token}"
}

cache {
  use_auto_auth_token = false
}

listener "tcp" {
    address = "${node_name}:8200"
    cluster_address = "${node_name}:8201"
    tls_disable = false
    tls_ca_file = "/opt/vault/config/vault-ca.pem"
    tls_cert_file = "/opt/vault/config/${node_name}.crt"
    tls_key_file = "/opt/vault/config/${node_name}.key"
}

ui=true
log_level = "INFO"
pid_file = "/opt/vault/data/vault.pid"
cluster_name = "${datacenter}-vault-cluster"
api_addr="https://${node_name}:8200"
cluster_addr="https://${node_name}:8201"
