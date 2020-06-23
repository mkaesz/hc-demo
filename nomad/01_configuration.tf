provider "consul" {
  address    = var.consul_server
  datacenter = var.datacenter
  token      = var.consul_master_token
}

resource "time_sleep" "wait_20_seconds" {
  create_duration = "60s"
}

resource "consul_acl_policy" "consul_client_policy" {
  name        = "${var.datacenter}-client-consul-server-nomad-${count.index}"
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

resource "consul_acl_policy" "nomad_server_policy" {
  name        = "${var.datacenter}-server-nomad-${count.index}"
  datacenters = ["${var.datacenter}"]
  rules       = <<-RULE
    node "${var.datacenter}-server-nomad-${count.index}" {
      policy = "write"
    }
    
    node "${var.datacenter}-server-nomad-${count.index}" {
      policy = "read"
    }
   
    service_prefix "" {
      policy = "write"
    }

    agent "${var.datacenter}-server-nomad-${count.index}" {
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

resource "consul_acl_policy" "nomad_worker_policy" {
  name        = "${var.datacenter}-worker-nomad-${count.index}"
  datacenters = ["${var.datacenter}"]
  rules       = <<-RULE
    node "${var.datacenter}-worker-nomad-${count.index}" {
      policy = "write"
    }
    
    node "${var.datacenter}-worker-nomad-${count.index}" {
      policy = "read"
    }
   
    service_prefix "" {
      policy = "write"
    }

    agent "${var.datacenter}-worker-nomad-${count.index}" {
      policy = "write"
    }
    RULE
  count = var.workers

 provisioner "remote-exec" {
   inline = [
       "consul acl token create -policy-name ${self.name} -secret ${random_uuid.consul_default_token_worker[count.index].result} -description '${self.name}' > /dev/null 2>&1",
     ]

   connection {
      type = "ssh"
      user = "mkaesz"
      host = "dc1-bastion.${var.domain}"
      private_key = file("~/.ssh/id_rsa")
   }
  }

 depends_on = [
    time_sleep.wait_20_seconds,
  ]
}
