resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = var.os_image
}

resource "libvirt_pool" "bastion" {
  name = "bastion"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-bastion"
}

resource "libvirt_volume" "volume" {
  name           = "volume-bastion"
  base_volume_id = libvirt_volume.os_image.id
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname            = "${var.datacenter}-bastion.${var.domain}"
    domain              = var.domain
    consul_ca_file      = base64encode(var.consul_ca_cert_pem)
    vault_ca_file       = base64encode(var.vault_ca_cert_pem)
    nomad_ca_file       = base64encode(var.nomad_ca_cert_pem)
    consul_cert_file    = base64encode(var.consul_cli_cert_pem)
    vault_cert_file     = base64encode(var.vault_cli_cert_pem)
    nomad_cert_file     = base64encode(var.nomad_cli_cert_pem)
    consul_key_file     = base64encode(var.consul_cli_private_key_pem)
    vault_key_file      = base64encode(var.vault_cli_private_key_pem)
    nomad_key_file      = base64encode(var.nomad_cli_private_key_pem)
    consul_master_token = var.consul_master_token
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/templates/network_config.cfg.tpl")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit-bastion.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.bastion.name
}

resource "libvirt_domain" "bastion" {
  name      = "${var.datacenter}-bastion"
  cloudinit = libvirt_cloudinit_disk.commoninit.id

  disk {
    volume_id = libvirt_volume.volume.id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true 
  }

  provisioner "local-exec" {
    when = create
    command = <<EOT
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl put /skydns/local/msk/${self.name} '{"host":"${self.network_interface.0.addresses.0}","ttl":60}'
EOT  
}

   provisioner "local-exec" {
    when = destroy 
    command = <<EOT
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl del /skydns/local/msk/${self.name}
EOT  
}  

provisioner "remote-exec" {
inline = [
  "mkdir -p ~/demo/{lb,nomad-bootstrap,vault-consul-nomad}"
]
}

provisioner "file" {
   source = "${path.module}/scripts/nomad-bootstrap.sh"
   destination = "/home/mkaesz/nomad-bootstrap.sh"
}

provisioner "file" {
   source = "~/workspace/vault-license.hclic"
   destination = "/home/mkaesz/vault-license.hclic"
}

provisioner "file" {
   source = "${path.module}/demo/vault-consul-nomad/accessdb.sql"
   destination = "/home/mkaesz/demo/vault-consul-nomad/accessdb.sql"
}

provisioner "file" {
   source = "${path.module}/demo/vault-consul-nomad/access-tables-policy.hcl"
   destination = "/home/mkaesz/demo/vault-consul-nomad/access-tables-policy.hcl"
}

provisioner "file" {
   source = "${path.module}/demo/vault-consul-nomad/connection.json"
   destination = "/home/mkaesz/demo/vault-consul-nomad/connection.json"
}
   
provisioner "file" {
   source = "${path.module}/demo/vault-consul-nomad/postgres-nomad-demo.nomad"
   destination = "/home/mkaesz/demo/vault-consul-nomad/postgres-nomad-demo.nomad"
}
   
provisioner "file" {
   source = "${path.module}/demo/nomad-bootstrap/nomad-cluster-role.json"
   destination = "/home/mkaesz/demo/nomad-bootstrap/nomad-cluster-role.json"
}

provisioner "file" {
   source = "${path.module}/demo/nomad-bootstrap/nomad-server-policy.hcl"
   destination = "/home/mkaesz/demo/nomad-bootstrap/nomad-server-policy.hcl"
}

provisioner "file" {
   source = "${path.module}/demo/vault-consul-nomad/nomad-vault-demo.nomad"
   destination = "/home/mkaesz/demo/vault-consul-nomad/nomad-vault-demo.nomad"
}
  
provisioner "file" {
   source = "${path.module}/demo/vault-consul-nomad/haproxy.nomad"
   destination = "/home/mkaesz/demo/vault-consul-nomad/haproxy.nomad"
}
  
provisioner "file" {
   source = "${path.module}/demo/vault-consul-nomad/deploy.sh"
   destination = "/home/mkaesz/demo/vault-consul-nomad/deploy.sh"
}

provisioner "file" {
   source = "${path.module}/demo/lb/demo-webapp.nomad"
   destination = "/home/mkaesz/demo/lb/demo-webapp.nomad"
}

provisioner "file" {
   source = "${path.module}/demo/lb/haproxy.nomad"
   destination = "/home/mkaesz/demo/lb/haproxy.nomad"
}
   
provisioner "file" {
   source = "${path.module}/scripts/vault-bootstrap.sh"
   destination = "/home/mkaesz/vault-bootstrap.sh"
}

provisioner "file" {
   source = "${path.module}/scripts/vault-login.sh"
   destination = "/home/mkaesz/vault-login.sh"
}

provisioner "file" {
   source = "${path.module}/scripts/vault-unseal.sh"
   destination = "/home/mkaesz/vault-unseal.sh"
}

   connection {
      type = "ssh"
      user = "mkaesz"
      #host = "dc1-bastion.${var.domain}"
      host = "dc1-bastion.msk.local"
      private_key = file("~/.ssh/id_rsa")
   }
}
