variable "consul_cluster_size" {
  description = "The size of the consul cluster."
  default = 3
}

variable "nomad_cluster_size" {
  description = "The size of the nomad cluster."
  default = 3
}

variable "nomad_workers" {
  description = "The number of nomad workers."
  default = 3
}

variable "datacenter" {
  description = "The datacenter."
  default = "dc1"
}

variable "domain" {
  default = "msk.local"
}

variable "os_image" {
  default = "http://192.168.0.171:8088/workspace/images/fedora32-kvm-hc-products-cloudinit.qcow2"
}
