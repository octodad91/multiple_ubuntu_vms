terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  pool = "images"
  user_data = file("${path.module}/cloud_init.cfg")
}

resource "libvirt_network" "my_bridge_network" {
  name = "my-bridge"
  mode = "bridge"
  bridge = "br0"
  autostart = true
}

resource "libvirt_domain" "multiple_uvm" {
  for_each   = var.vms
  name       = each.key
  memory     = each.value.memory
  vcpu       = each.value.vcpu
  cloudinit  = libvirt_cloudinit_disk.commoninit.id
  qemu_agent = true

  network_interface {
     network_name = libvirt_network.my_bridge_network.name
     wait_for_lease = true

  }

  disk {
    volume_id = libvirt_volume.multiple_uvm[each.key].id
  }

  console {
    type = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

resource "libvirt_volume" "ubuntu_base" {
  name = "ubuntu-noble-base.qcow2"
  pool = "images"
  source = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

resource "libvirt_volume" "multiple_uvm" {
  for_each = var.vms

  name   = "${each.key}.qcow2"
  pool   = "images"
  base_volume_id = libvirt_volume.ubuntu_base.id
  format = "qcow2"
}

output "vm_ips" {
  value = {
    for k, d in libvirt_domain.multiple_uvm :
    k => try(d.network_interface[0].addresses[0], null)
  }
}
