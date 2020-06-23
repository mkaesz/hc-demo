provider "consul" {
  address    = var.consul_server 
  datacenter = var.datacenter
  token      = random_uuid.consul_master_token.result
}

resource "time_sleep" "wait_20_seconds" {
  depends_on = [libvirt_domain.consul_server]

  create_duration = "40s"
}

resource "consul_license" "license" {
  license = file("~/workspace/consul-license.hclic")
  depends_on = [
    time_sleep.wait_20_seconds,
  ]
}

resource "consul_autopilot_config" "config" {
    cleanup_dead_servers      =  false
    last_contact_threshold    =  "1s"
    max_trailing_logs         =  500
  depends_on = [
    time_sleep.wait_20_seconds,
  ]
}

resource "consul_acl_policy" "agent_policy" {
  name        = "${var.datacenter}-server-consul-${count.index}"
  datacenters = ["${var.datacenter}"]
  rules       = <<-RULE
    node "${var.datacenter}-server-consul-${count.index}" {
      policy = "write"
    }
    agent "${var.datacenter}-server-consul-${count.index}" {
      policy = "write"
    }
    RULE
  count = var.cluster_size
  depends_on = [
    time_sleep.wait_20_seconds,
  ]
}
