resource "libvirt_pool" "vault" {
  name = "vault"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-vault"
}

resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = var.os_image
}

resource "tls_private_key" "vault_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "vault_ca" {
  key_algorithm   = tls_private_key.vault_ca.algorithm
  private_key_pem = tls_private_key.vault_ca.private_key_pem

  subject {
    common_name  = "vault.${var.domain}"
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

resource "tls_private_key" "vault" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}
