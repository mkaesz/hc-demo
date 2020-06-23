resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = var.os_image
}

resource "libvirt_pool" "consul" {
  name = "consul"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-consul"
}

locals {
  consul_cluster_servers_expanded = {
    for i in range(0, var.cluster_size):i => format("%s%s%d%s", var.datacenter, "-server-consul-", i, ".${var.domain}")
  }
}

resource "tls_private_key" "consul_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "consul_ca" {
  key_algorithm   = tls_private_key.consul_ca.algorithm
  private_key_pem = tls_private_key.consul_ca.private_key_pem

  subject {
    common_name  = "consul.${var.domain}"
    organization = "msk"
  }

  validity_period_hours = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
  ]
}

resource "tls_private_key" "consul" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "random_string" "consul_gossip_password" {
  length = 16
  special = true
}

resource "random_uuid" "consul_master_token" { }

resource "libvirt_volume" "volume_server" {
  name           = "volume-consul-server-${count.index}"
  base_volume_id = libvirt_volume.os_image.id
  count	         = var.cluster_size
}

resource "tls_cert_request" "consul_server" {
  key_algorithm   = tls_private_key.consul.algorithm
  private_key_pem = tls_private_key.consul.private_key_pem

  dns_names = [
    "${var.datacenter}-server-consul-${count.index}",
    "${var.datacenter}-server-consul-${count.index}.${var.domain}",
    "server.${var.datacenter}.consul",
    "localhost",
    "127.0.0.1",
  ]

  subject {
    common_name  = "${var.datacenter}-server-consul-${count.index}.${var.domain}"
    organization = "msk"
  }

  count = var.cluster_size
}

resource "tls_locally_signed_cert" "consul_server" {
  cert_request_pem = tls_cert_request.consul_server[count.index].cert_request_pem

  ca_key_algorithm   = tls_private_key.consul_ca.algorithm
  ca_private_key_pem = tls_private_key.consul_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.consul_ca.cert_pem

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

data "template_file" "consul_server_config" {
  template = "${file("${path.module}/templates/consul-server.json.tpl")}"
  vars = {
    node_name            = "${var.datacenter}-server-consul-${count.index}.${var.domain}"
    cluster_size         = var.cluster_size
    consul_cluster_nodes = jsonencode(values(local.consul_cluster_servers_expanded))
    gossip_password      = base64encode(random_string.consul_gossip_password.result)
    datacenter           = var.datacenter
    consul_master_token  = random_uuid.consul_master_token.result
  }
  count = var.cluster_size
}

data "template_file" "user_data_consul_server" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname      = "${var.datacenter}-server-consul-${count.index}.${var.domain}"
    consul_config = base64encode(data.template_file.consul_server_config[count.index].rendered)
    ca_file       = base64encode(tls_self_signed_cert.consul_ca.cert_pem)
    cert_file     = base64encode(tls_locally_signed_cert.consul_server[count.index].cert_pem)
    key_file      = base64encode(tls_private_key.consul.private_key_pem)
    domain        = var.domain
  }
  count	= var.cluster_size
}

data "template_file" "network_config_consul_server" {
  template = file("${path.module}/templates/network_config.cfg.tpl")
}

resource "libvirt_cloudinit_disk" "commoninit_consul_server" {
  name           = "commoninit-consul-server-${count.index}.iso"
  user_data      = data.template_file.user_data_consul_server[count.index].rendered
  network_config = data.template_file.network_config_consul_server.rendered
  pool           = libvirt_pool.consul.name
  count          = var.cluster_size
}

resource "libvirt_domain" "consul_server" {
  name = "${var.datacenter}-server-consul-${count.index}"
  count = var.cluster_size

  cloudinit = libvirt_cloudinit_disk.commoninit_consul_server[count.index].id

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
sleep 5
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl del /skydns/local/msk/${self.name} > /dev/null 2>&1
EOT  
}
}
