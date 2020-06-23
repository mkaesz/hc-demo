provider "consul" {
  address    = var.consul_server
  datacenter = var.datacenter
  token      = var.consul_master_token
}

resource "time_sleep" "wait_20_seconds" {
  create_duration = "60s"
}

resource "consul_acl_policy" "consul_client_policy" {
  name        = "${var.datacenter}-client-consul-server-vault-${count.index}"
  datacenters = ["${var.datacenter}"]
  rules       = <<-RULE
    node "${var.datacenter}-client-consul-${count.index}" {
      policy = "write"
    }
    agent "${var.datacenter}-client-consul-${count.index}" {
      policy = "write"
    }
    RULE
  count = var.cluster_size
  depends_on = [
    time_sleep.wait_20_seconds,
  ]
}

resource "consul_acl_policy" "vault_server_policy" {
  name        = "${var.datacenter}-server-vault-${count.index}"
  datacenters = ["${var.datacenter}"]
  rules       = <<-RULE
    node_prefix "" {
      policy = "write"
    }

    key_prefix "vault/" {
      policy = "write"
    }

    service "vault" {
      policy = "write"
    }

    agent_prefix "" {
      policy = "write"
    }

    session_prefix "" {
      policy = "write"
    }
    RULE
  count = var.cluster_size
  depends_on = [
   time_sleep.wait_20_seconds,
  ]

  provisioner "remote-exec" {
   inline = [
       "consul acl token create -policy-name ${self.name} -secret ${random_uuid.consul_default_token[count.index].result} -description '${self.name}' > /dev/null 2>&1",
     ]

 connection {
   type = "ssh"
   user = "mkaesz"
   host = "dc1-bastion.${var.domain}"
   private_key = file("~/.ssh/id_rsa")
 }
}
}
