output "nomad_ca_cert_pem" {
  value = tls_self_signed_cert.nomad_ca.cert_pem
}

output "nomad_cli_cert_pem" {
  value = tls_locally_signed_cert.nomad_cli.cert_pem
}

output "nomad_cli_private_key_pem" {
  value = tls_private_key.nomad.private_key_pem
}
