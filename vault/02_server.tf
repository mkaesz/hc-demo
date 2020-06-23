resource "libvirt_volume" "volume_server" {
  name           = "volume-vault-server-${count.index}"
  base_volume_id = libvirt_volume.os_image.id
  count	         = var.cluster_size
}

resource "tls_cert_request" "consul_client" {
  key_algorithm   = var.consul_private_key_algorithm
  private_key_pem = var.consul_private_key_pem

  dns_names = [
    "${var.datacenter}-client-consul-${count.index}",
    "${var.datacenter}-server-vault-${count.index}.${var.domain}",
    "client.${var.datacenter}.consul",
    "localhost"
  ]

  ip_addresses = [
    "127.0.0.1"
  ]

  subject {
    common_name  = "${var.datacenter}-client-consul-${count.index}.${var.domain}"
    organization = "msk"
  }
  count = var.cluster_size
}

resource "tls_locally_signed_cert" "consul_client" {
  cert_request_pem   = tls_cert_request.consul_client[count.index].cert_request_pem
  ca_key_algorithm   = var.consul_private_key_algorithm
  ca_private_key_pem = var.consul_private_key_pem
  ca_cert_pem        = var.consul_ca_cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
  count = var.cluster_size
}

resource "tls_cert_request" "vault_server" {
  key_algorithm   = tls_private_key.vault.algorithm
  private_key_pem = tls_private_key.vault.private_key_pem

  dns_names = [
    "${var.datacenter}-server-vault-${count.index}",
    "${var.datacenter}-server-vault-${count.index}.${var.domain}",
    "active.${var.datacenter}-vault-cluster.service.consul",
    "active.${var.datacenter}-vault.service.consul",
    "server.${var.datacenter}.vault",
    "server.global.vault",
    "server.europe.vault",
    "localhost",
    "127.0.0.1",
  ]

  subject {
    common_name  = "${var.datacenter}-server-vault-${count.index}.${var.domain}"
    organization = "msk"
  }
  count = var.cluster_size
}

resource "tls_locally_signed_cert" "vault_server" {
  cert_request_pem   = tls_cert_request.vault_server[count.index].cert_request_pem
  ca_key_algorithm   = tls_private_key.vault_ca.algorithm
  ca_private_key_pem = tls_private_key.vault_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.vault_ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
  count = var.cluster_size
}

data "template_file" "consul_client_config" {
  template = "${file("${path.module}/templates/consul-client.json.tpl")}"
  vars = {
    node_name = "${var.datacenter}-server-vault-${count.index}.${var.domain}"
    consul_cluster_nodes = jsonencode(values(var.consul_cluster_servers))
    gossip_password = base64encode(var.consul_gossip_password)
    datacenter = var.datacenter
    consul_default_token = random_uuid.consul_default_token[count.index].result
  }
  count = var.cluster_size
}

data "template_file" "vault_server_config" {
  template = "${file("${path.module}/templates/vault-server.hcl.tpl")}"
  vars = {
    node_name        = "${var.datacenter}-server-vault-${count.index}.${var.domain}"
    datacenter       = var.datacenter
    consul_default_token = random_uuid.consul_default_token[count.index].result
  }
  count = var.cluster_size
}

data "template_file" "user_data_vault_server" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname         = "${var.datacenter}-server-vault-${count.index}.${var.domain}"
    consul_config    = base64encode(data.template_file.consul_client_config[count.index].rendered)
    vault_config     = base64encode(data.template_file.vault_server_config[count.index].rendered)
    consul_ca_file   = base64encode(var.consul_ca_cert_pem)
    vault_ca_file    = base64encode(tls_self_signed_cert.vault_ca.cert_pem)
    consul_cert_file = base64encode(tls_locally_signed_cert.consul_client[count.index].cert_pem)
    vault_cert_file  = base64encode(tls_locally_signed_cert.vault_server[count.index].cert_pem)
    consul_key_file  = base64encode(var.consul_private_key_pem)
    vault_key_file   = base64encode(tls_private_key.vault.private_key_pem)
    vault_mode       = "server"
  }
  count	= var.cluster_size
}

data "template_file" "network_config_client" {
  template = file("${path.module}/templates/network_config.cfg.tpl")
}

resource "libvirt_cloudinit_disk" "commoninit_vault_server" {
  name           = "commoninit-vault-server-${count.index}.iso"
  user_data      = data.template_file.user_data_vault_server[count.index].rendered
  network_config = data.template_file.network_config_client.rendered
  pool           = libvirt_pool.vault.name
  count          = var.cluster_size
}

resource "random_uuid" "consul_default_token" {
  count = var.cluster_size
}

resource "libvirt_domain" "vault_server" {
  name       = "${var.datacenter}-server-vault-${count.index}"
  count      = var.cluster_size
  cloudinit  = libvirt_cloudinit_disk.commoninit_vault_server[count.index].id

  disk {
    volume_id = element(libvirt_volume.volume_server.*.id, count.index)
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  provisioner "local-exec" {
    when = create
    command = <<EOT
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl put /skydns/local/msk/${self.name} '{"host":"${self.network_interface.0.addresses.0}","ttl":60}'  > /dev/null 2>&1
EOT
}

  provisioner "local-exec" {
    when = destroy
    command = <<EOT
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl del /skydns/local/msk/${self.name} > /dev/null 2>&1
EOT
}

depends_on = [
  consul_acl_policy.vault_server_policy
]
}


