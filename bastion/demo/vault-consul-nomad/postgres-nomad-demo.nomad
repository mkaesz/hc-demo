job "postgres-nomad-demo" {
  datacenters = ["dc1"]

  group "db" {

    task "server" {
      driver = "docker"

      config {
        image = "hashicorp/postgres-nomad-demo:latest"
        network_mode = "nomad"
        port_map {
          db = 5432
        }
      }
      resources {
        network {
	  mode = "host"
          port  "db"{
            static = 5432
          }
        }
      }

      service {
        name = "database"
        port = "db"
        address_mode = "host"

        check {
          type     = "tcp"
          interval = "2s"
          timeout  = "2s"
        }
      }
    }
  }
}
