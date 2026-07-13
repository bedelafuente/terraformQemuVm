# 🖥️ Lab DevOps: Terraform + KVM + Ansible

Proyecto de aprendizaje para automatizar la creación de máquinas virtuales locales con **Terraform** y configurarlas con **Ansible**.

---

## 📐 Arquitectura del Proyecto

```
Tu máquina (host)
└── KVM/libvirt (hipervisor)
    └── ubuntu-vm (máquina virtual)
        ├── Ubuntu Server 22.04 (Jammy)
        ├── Usuario: ubuntu (con sudo)
        ├── Acceso SSH por llave pública
        └── Red NAT 192.168.122.0/24
```

### Flujo de creación con Terraform

```
main.tf
  ├── libvirt_volume "ubuntu_base"     → Registra la imagen .img base (solo lectura)
  ├── libvirt_volume "UbuntuServer"    → Crea disco VM (Copy-on-Write desde la base, 8GB)
  ├── libvirt_cloudinit_disk "commoninit" → ISO con config inicial (usuario, SSH, contraseña)
  └── libvirt_domain "ubuntu-vm"       → La VM: 2 vCPU, 2GB RAM, red NAT
```

---

## 📁 Estructura de Archivos

```
preparacionDevOps/
├── main.tf              # Infraestructura completa en Terraform
├── variables.tf         # Declaración de variables (a implementar)
├── terraform.tfvars     # Valores de las variables (a implementar)
├── reiniciarLanzar.sh   # Script: destruye y recrea toda la infra
├── limpiarVirsh.sh      # Script: limpia recursos huérfanos en libvirt
└── README.md            # Este archivo
```

---

## ⚙️ Requisitos Previos

### Software necesario
- `terraform` (cualquier versión >= 1.0)
- `libvirt` / `qemu-kvm` instalado y activo
- `virsh` (cliente de línea de comandos para libvirt)

### Configuración del sistema (hecha una sola vez)
En `/etc/libvirt/qemu.conf` se deben tener estas líneas descomentadas:
```ini
user = "root"
group = "root"
security_driver = "none"
```
Luego reiniciar libvirt:
```bash
sudo systemctl restart libvirtd
```
> ⚠️ Esta configuración es solo válida para laboratorio local. En producción se configuran permisos granulares.

### Imagen base de Ubuntu
Se necesita la imagen Cloud de Ubuntu 22.04 en:
```
/home/benja/osimages/jammy-server-cloudimg-amd64.img
```
Descargable desde: https://cloud-images.ubuntu.com/jammy/current/

### Llave SSH
Tu llave pública en `~/.ssh/id_rsa.pub`. Si no existe:
```bash
ssh-keygen -t rsa -b 4096
```

---

## 🚀 Uso

### Primera vez (inicializar Terraform)
```bash
terraform init
```
Descarga el proveedor `dmacvicar/libvirt`.

### Ver qué se va a crear (sin ejecutar nada)
```bash
terraform plan
```

### Crear la VM
```bash
terraform apply
```
Al finalizar, imprime:
```
vm_ip   = "192.168.122.X"
vm_mac  = "52:54:00:XX:XX:XX"
vm_name = "ubuntu-vm"
```

### Destruir la VM
```bash
terraform destroy
```

### Ciclo rápido destroy → apply (script)
```bash
./reiniciarLanzar.sh
```

---

## 🔗 Conectarse a la VM

### Por SSH (recomendado)
```bash
ssh ubuntu@<vm_ip>
# Ejemplo: ssh ubuntu@192.168.122.234
```
No requiere contraseña (usa llave pública).

### Por consola serie (para diagnóstico)
```bash
virsh console ubuntu-vm
# Usuario: ubuntu
# Contraseña: devops1234
# Para salir: Ctrl + ]
```

### Ver la IP en cualquier momento
```bash
terraform output vm_ip
```

---

## 🧹 Limpieza de Recursos Huérfanos

Si un `terraform apply` falla a la mitad, pueden quedar recursos huérfanos en libvirt que Terraform ya no conoce. Síntomas:
- `Error: storage volume 'X' exists already`
- `Error: domain 'ubuntu-vm' already exists`

Diagnóstico:
```bash
virsh list --all         # Ver todas las VMs
virsh vol-list default   # Ver todos los volúmenes
```

Limpieza manual:
```bash
virsh undefine ubuntu-vm
virsh vol-delete commoninit.iso --pool default
virsh vol-delete UbuntuServer --pool default
virsh vol-delete ubuntu_base.qcow2 --pool default
```

O usar el script (requiere revisar los nombres primero):
```bash
sudo bash limpiarVirsh.sh
```

---

## 💡 Conceptos Aprendidos

| Concepto | Descripción |
|---|---|
| **Provider** | Plugin que conecta Terraform con libvirt/KVM |
| **Resource** | Cada elemento de infraestructura que Terraform gestiona |
| **Output** | Valores que Terraform imprime al terminar (ej: IP de la VM) |
| **`base_volume_id`** | Copy-on-Write: la VM comparte la imagen base sin copiarla |
| **Cloud-Init** | Servicio que configura la VM en el primer arranque |
| **`terraform plan`** | Muestra qué se va a crear/modificar/destruir SIN ejecutar nada |
| **`terraform.tfstate`** | Archivo donde Terraform guarda el estado de la infra creada |
| **`(known after apply)`** | Valor que solo se conoce después de crear el recurso (IPs, IDs, etc.) |

---

## 🗺️ Hoja de Ruta: Siguientes Pasos

### Fase 2: Variables y Reutilización
- [ ] Declarar variables en `variables.tf` (nombre de VM, RAM, CPUs, IP base, etc.)
- [ ] Asignar valores en `terraform.tfvars`
- [ ] Referenciarlas en `main.tf` con `var.nombre_variable`

### Fase 3: Ansible
- [ ] Instalar Ansible en el host
- [ ] Crear el archivo de inventario (`inventory.ini`) con la IP de la VM
- [ ] Escribir un playbook básico (`playbook.yml`) para instalar paquetes
- [ ] Ejecutar el playbook: `ansible-playbook -i inventory.ini playbook.yml`

### Fase 4: Integración completa
- [ ] Usar el output de Terraform para generar el inventario de Ansible automáticamente
- [ ] Pasar archivos a la VM con `ansible` módulo `copy` o `scp`
- [ ] Crear múltiples VMs con `count` o `for_each` en Terraform

---

## 📤 Transferencia de Archivos a la VM

Para copiar archivos a tu VM sin Ansible:
```bash
# Copiar un archivo
scp archivo.txt ubuntu@192.168.122.X:/home/ubuntu/

# Copiar una carpeta completa
scp -r mi_carpeta/ ubuntu@192.168.122.X:/home/ubuntu/
```

Con Ansible (más poderoso, lo veremos en Fase 3):
```yaml
- name: Copiar archivo a la VM
  copy:
    src: archivo_local.txt
    dest: /home/ubuntu/archivo_local.txt
```

---

## 🐛 Problemas Conocidos y Soluciones

| Error | Causa | Solución |
|---|---|---|
| `Permission denied` al crear dominio | AppArmor / QEMU no corre como root | Configurar `user = "root"` en `qemu.conf` |
| `volume 'X' exists already` | Recurso huérfano de apply fallido | `virsh vol-delete X --pool default` |
| `domain 'ubuntu-vm' already exists` | VM huérfana de apply fallido | `virsh undefine ubuntu-vm` |
| Cloud-Init no aplica config | `#cloud-config` no es la primera línea | Eliminar líneas en blanco antes del header |
| SSH: `Permission denied (publickey)` | Llave SSH no aplicada por Cloud-Init | Verificar YAML de `user_data` y redesplegar |
| Consola: `Login incorrect` | `chpasswd` con `password:valor` (sin espacio) | `password: valor` con espacio después de `:` |
