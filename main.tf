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
  source = var.ruta_imagen_os
  format = "qcow2"
}

resource "libvirt_volume" "UbuntuServer" {

  name           = "UbuntuServer"
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = var.size_maquina
  format         = "qcow2"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = <<EOF
#cloud-config
ssh_authorized_keys:
  - ${file(var.ssh_public_key_path)}
chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: devops1234
      type: text
EOF
}

resource "libvirt_domain" "ubuntu-vm" {
  memory    = var.size_ram
  vcpu      = var.vcpu_maquina
  name      = var.vm_name
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



