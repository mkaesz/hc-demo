resource "libvirt_pool" "nomad" {
  name = "nomad"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-nomad"
}

resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = var.os_image 
}

resource "tls_private_key" "nomad_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "nomad_ca" {
  key_algorithm   = tls_private_key.nomad_ca.algorithm
  private_key_pem = tls_private_key.nomad_ca.private_key_pem

  subject {
    common_name  = "nomad.${var.domain}"
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

resource "tls_private_key" "nomad" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "random_string" "nomad_gossip_password" {
  length = 16
  special = true
}
