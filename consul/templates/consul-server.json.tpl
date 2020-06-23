{
  "server": true,
  "datacenter": "${datacenter}",
  "primary_datacenter": "${datacenter}",
  "ui": true,
  "encrypt": "${gossip_password}",
  "log_level": "INFO",
  "node_name": "${node_name}",
  "disable_remote_exec": false,
  "rejoin_after_leave": true,
  "enable_syslog": true,
  "non_voting_server": false,
  "disable_update_check": true,
  "bind_addr": "{{ GetInterfaceIP \"eth0\" }}",
  "client_addr": "0.0.0.0",
  "enable_script_checks": false,
  "enable_local_script_checks": true,
  "bootstrap_expect": ${cluster_size},
  "retry_join": ${consul_cluster_nodes},
  "verify_incoming": true,
  "log_file": "/opt/consul/data/",
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "ca_file": "/opt/consul/config/consul-ca.pem",
  "cert_file": "/opt/consul/config/${node_name}.crt",
  "key_file": "/opt/consul/config/${node_name}.key",
  "recursors": [
    "192.168.0.171"
  ],
  "auto_encrypt": {
    "allow_tls": true
  },
  "ports": {
    "http": 8500,
    "https": 8501
  },
  "connect": {
    "enabled": false
  },
  "acl": {
    "enabled": true,
    "default_policy": "allow", 
    "tokens": {
      "master": "${consul_master_token}",
      "agent": "${consul_master_token}"
    },
    "enable_token_persistence": true
  },
  "node_meta": {
    "os": "fedora"
  }
}
