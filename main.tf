terraform {

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu_base.qcow2"
  source = "/home/benja/osimages/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
  # size   = 8589934592 para 8G
}

resource "libvirt_volume" "UbuntuServer" {

  name           = "UbuntuServer"
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = 8589934592
  format         = "qcow2"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = <<EOF
#cloud-config
ssh_authorized_keys:
  - ${file("~/.ssh/id_rsa.pub")}
chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: devops1234
      type: text
EOF
}

resource "libvirt_domain" "ubuntu-vm" {
  memory    = 2048
  vcpu      = 2
  name      = "ubuntu-vm"
  cloudinit = libvirt_cloudinit_disk.commoninit.id

  disk {
    volume_id = libvirt_volume.UbuntuServer.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
}

# try(expresion que puede fallar, expresion por defecto)
output "vm_ip" {
  value       = try(libvirt_domain.ubuntu-vm.network_interface[0].addresses[0], "Sin ip (VM shutted down)")
  description = "La ip de la maquina virtual"
}

output "vm_mac" {
  value       = libvirt_domain.ubuntu-vm.network_interface[0].mac
  description = "La mac de la maquina virtual"
}

output "vm_name" {
  value       = libvirt_domain.ubuntu-vm.name
  description = "El nombre de la maquina virtual"
}

