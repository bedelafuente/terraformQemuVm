# Aquí voy a declarar las variables de mi main.tf para separar responsabilidades. Esto logra código más limpio.

variable "size_maquina" {
  type        = number
  description = "Tamaño de la maquina en megabytes"
  default     = 8589934592
}

variable "size_ram" {
  type        = number
  description = "Tamaño de ram de la maquina en bytes"
  default     = 2048
}

variable "ruta_imagen_os" {
  type        = string
  description = "Ruta a la imagen del sistema operativo"
  default     = "/home/benja/Descargas/ISOs/jammy-server-cloudimg-amd64.img"
}

variable "vcpu_maquina" {
  type        = number
  description = "Cantidad de nucleos virtuales que de los que dispondrá la maquina"
  default     = 2
}

variable "vm_name" {
  type    = string
  default = "ubuntu-vm"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
