resource "libvirt_volume" "volume_worker" {
  name           = "volume-nomad-worker-${count.index}"
  base_volume_id = libvirt_volume.os_image.id
  count	         = var.workers
}

resource "tls_cert_request" "consul_client_worker" {
  key_algorithm   = var.consul_private_key_algorithm
  private_key_pem = var.consul_private_key_pem

  dns_names = [
    "${var.datacenter}-client-consul-${count.index}",
    "${var.datacenter}-worker-nomad-${count.index}",
    "${var.datacenter}-worker-nomad-${count.index}.${var.domain}",
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
  count = var.workers
}

resource "tls_locally_signed_cert" "consul_client_worker" {
  cert_request_pem   = tls_cert_request.consul_client_worker[count.index].cert_request_pem
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
  count = var.workers
}

resource "tls_cert_request" "vault_client_worker" {
  key_algorithm   = var.vault_private_key_algorithm
  private_key_pem = var.vault_private_key_pem

  dns_names = [
    "${var.datacenter}-client-vault-${count.index}",
    "${var.datacenter}-worker-nomad-${count.index}",
    "${var.datacenter}-worker-nomad-${count.index}${var.domain}",
    "client.${var.datacenter}.consul",
    "localhost"
  ]

  ip_addresses = [
    "127.0.0.1"
  ]

  subject {
    common_name  = "${var.datacenter}-client-vault-${count.index}.${var.domain}"
    organization = "msk"
  }
  count = var.workers
}

resource "tls_locally_signed_cert" "vault_client_worker" {
  cert_request_pem   = tls_cert_request.vault_client_worker[count.index].cert_request_pem
  ca_key_algorithm   = var.vault_private_key_algorithm
  ca_private_key_pem = var.vault_private_key_pem
  ca_cert_pem        = var.vault_ca_cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
  count = var.workers
}

resource "tls_cert_request" "nomad_worker" {
  key_algorithm   = tls_private_key.nomad.algorithm
  private_key_pem = tls_private_key.nomad.private_key_pem

  dns_names = [
    "${var.datacenter}-worker-nomad-${count.index}",
    "${var.datacenter}-worker-nomad-${count.index}.${var.domain}",
    "server.${var.datacenter}.nomad",
    "server.global.nomad",
    "server.europe.nomad",
    "localhost",
    "127.0.0.1",
  ]

  subject {
    common_name  = "${var.datacenter}-worker-nomad-${count.index}.${var.domain}"
    organization = "msk"
  }
  count = var.workers
}

resource "tls_locally_signed_cert" "nomad_worker" {
  cert_request_pem   = tls_cert_request.nomad_worker[count.index].cert_request_pem
  ca_key_algorithm   = tls_private_key.nomad_ca.algorithm
  ca_private_key_pem = tls_private_key.nomad_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.nomad_ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
  count = var.workers
}

resource "random_uuid" "consul_default_token_worker" {
  count = var.workers
}

data "template_file" "consul_client_worker_config" {
  template = "${file("${path.module}/templates/consul-client.json.tpl")}"
  vars = {
    node_name = "${var.datacenter}-worker-nomad-${count.index}.${var.domain}"
    consul_cluster_nodes = jsonencode(values(var.consul_cluster_servers))
    gossip_password = base64encode(var.consul_gossip_password)
    datacenter = var.datacenter
    consul_default_token = random_uuid.consul_default_token_worker[count.index].result
  }
  count = var.workers
}

data "template_file" "nomad_worker_config" {
  template = "${file("${path.module}/templates/nomad-worker.hcl.tpl")}"
  vars = {
    node_name        = "${var.datacenter}-worker-nomad-${count.index}.${var.domain}"
    datacenter       = var.datacenter
    domain           = var.domain
  }
  count = var.workers
}

data "template_file" "user_data_nomad_worker" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname = "${var.datacenter}-worker-nomad-${count.index}.${var.domain}"
    consul_config    = base64encode(data.template_file.consul_client_worker_config[count.index].rendered)
    nomad_config     = base64encode(data.template_file.nomad_worker_config[count.index].rendered)
    consul_ca_file   = base64encode(var.consul_ca_cert_pem)
    vault_ca_file    = base64encode(var.vault_ca_cert_pem)
    nomad_ca_file    = base64encode(tls_self_signed_cert.nomad_ca.cert_pem)
    consul_cert_file = base64encode(tls_locally_signed_cert.consul_client_worker[count.index].cert_pem)
    vault_cert_file  = base64encode(tls_locally_signed_cert.vault_client_worker[count.index].cert_pem)
    nomad_cert_file  = base64encode(tls_locally_signed_cert.nomad_worker[count.index].cert_pem)
    consul_key_file  = base64encode(var.consul_private_key_pem)
    vault_key_file   = base64encode(var.vault_private_key_pem)
    nomad_key_file   = base64encode(tls_private_key.nomad.private_key_pem) 
  }
  count	= var.workers
}

data "template_file" "network_config" {
  template = file("${path.module}/templates/network_config.cfg.tpl")
}

resource "libvirt_cloudinit_disk" "commoninit_nomad_worker" {
  name           = "commoninit-nomad-worker-${count.index}.iso"
  user_data      = data.template_file.user_data_nomad_worker[count.index].rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.nomad.name
  count          = var.workers
}

resource "libvirt_domain" "nomad_worker" {
  name = "${var.datacenter}-worker-nomad-${count.index}"
  memory = "4096"
  vcpu   = 3
  count = var.workers

  cloudinit = libvirt_cloudinit_disk.commoninit_nomad_worker[count.index].id

  disk {
    volume_id = element(libvirt_volume.volume_worker.*.id, count.index)
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true 
  }

  provisioner "local-exec" {
    when = create
    command = <<EOT
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1 
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl put /skydns/local/msk/${self.name} '{"host":"${self.network_interface.0.addresses.0}","ttl":60}' > /dev/null 2>&1
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
    consul_acl_policy.nomad_worker_policy,
  ]
}
