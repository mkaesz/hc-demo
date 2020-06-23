{
  "server": false,
  "datacenter": "${datacenter}",
  "primary_datacenter": "${datacenter}",
  "ui": false,
  "log_level": "INFO",
  "node_name": "${node_name}",
  "encrypt": "${gossip_password}",
  "disable_remote_exec": false,
  "rejoin_after_leave": true,
  "enable_syslog": true,
  "disable_update_check": true,
  "bind_addr": "{{ GetInterfaceIP \"eth0\" }}",
  "client_addr": "127.0.0.1",
  "enable_script_checks": false,
  "log_file": "/opt/consul/data/",
  "enable_local_script_checks": true,
  "retry_join": ${consul_cluster_nodes},
  "log_file": "/opt/consul/data/",
  "verify_incoming": true,
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "ca_file": "/opt/consul/config/consul-ca.pem",
  "cert_file": "/opt/consul/config/${node_name}.crt",
  "key_file": "/opt/consul/config/${node_name}.key",
  "acl": {
    "enabled": true,
    "enable_token_persistence": true,
    "tokens": {
      "agent": "${consul_default_token}"
    }
  },
  "auto_encrypt": {
    "tls": true
  },
  "recursors": [
    "192.168.0.171"
  ],
  "ports": {
    "http": -1,
    "https": 8501
  },
  "node_meta": {
    "os": "fedora"
  }
}
