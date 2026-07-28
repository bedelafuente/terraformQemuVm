## Tener este archivo aparte, sirve para que el main.tf solo se encargue de infraestructura.

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
