job "nomad-vault-demo" {
  datacenters = ["dc1"]

  group "demo" {
    count = 2
    task "server" {

      vault {
        policies = ["access-tables"]
      }

      driver = "docker"
      config {
        image = "hashicorp/nomad-vault-demo:latest"
        network_mode = "nomad"
        port_map {
          http = 8080
        }

        volumes = [
          "secrets/config.json:/etc/demo/config.json"
        ]
      }

      template {
        data = <<EOF
{{ with secret "database/creds/accessdb" }}
  {
    "host": "database.service.consul",
    "port": 5432,
    "username": "{{ .Data.username }}",
    "password": {{ .Data.password | toJSON }},
    "db": "postgres"
  }
{{ end }}
EOF
        destination = "secrets/config.json"
      }

      resources {
        network {
	  mode = "host"
          port "http" {}
        }
      }

      service {
        name = "nomad-vault-demo"
        port = "http"
        address_mode = "host"

        tags = [
          "urlprefix-/",
        ]

        check {
          type     = "tcp"
          interval = "2s"
          timeout  = "2s"
        }
      }
    }
  }
}
