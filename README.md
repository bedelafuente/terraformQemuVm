# 🖥️ Lab DevOps: Terraform + KVM/libvirt + Ansible (Roles) + Cloudflare Zero Trust

Proyecto de automatización de infraestructura como código (**IaC**) y gestión de configuración modular para desplegar servidores web sobre **KVM/libvirt** y exponerlos de forma segura a internet con **Cloudflare Tunnels**.

---

## 📐 Arquitectura del Proyecto

```text
Tu Máquina (Host)
└── KVM / libvirt (Hipervisor)
    └── ubuntu-vm (Máquina Virtual Ubuntu 22.04)
        ├── Red NAT Interna: 192.168.122.0/24
        ├── Ansible Config Management (Roles)
        │   ├── Rol 1: Nginx (Servidor Web + HTML Personalizado)
        │   └── Rol 2: Cloudflare (Agente cloudflared)
        └── Cloudflare Zero Trust Tunnel
            └── 🌐 Enlace HTTPS Público (TryCloudflare)
```

---

## 🏗️ Flujo de Automatización (End-to-End)

```text
[ Terraform ] ──(Crea VM & Red)──> [ Ansible Roles ] ──(Configura Nginx)──> [ Cloudflare Tunnel ] ──(Acceso Global HTTPS)
```

1. **Terraform (IaC)**: Provisiona el volumen base `qcow2`, el disco `cloud-init` (con claves SSH) y la máquina virtual parametrizada.
2. **Ansible (Roles)**:
   * **`roles/nginx`**: Actualiza paquetes, instala Nginx, habilita el servicio y despliega el sitio web personalizado.
   * **`roles/cloudflare`**: Instala el binario `cloudflared`, inicia el túnel saliente como servicio en segundo plano y extrae la URL pública.
3. **Cloudflare Zero Trust**: Expone la página web a internet sin abrir puertos en el router ni requerir IP pública.

---

## 📁 Estructura del Repositorio

```text
preparacionDevOps/
├── main.tf                 # Recursos principales de infraestructura (libvirt)
├── variables.tf            # Declaración parametrizada de variables de Terraform
├── outputs.tf              # Salidas del estado (IP, MAC, Nombre VM)
├── reiniciarLanzar.sh      # Script de automatización End-to-End
├── limpiarVirsh.sh         # Script de mantenimiento/limpieza de libvirt
├── .gitignore              # Exclusión de binarios y estados locales
├── README.md               # Documentación del laboratorio
└── ansible/
    ├── inventory.ini       # Inventario de hosts dinámico
    ├── site.yml            # Playbook orquestador principal
    └── roles/
        ├── nginx/          # Rol: Servidor Web Nginx
        │   ├── tasks/main.yml
        │   ├── handlers/main.yml
        │   └── files/index.html
        └── cloudflare/     # Rol: Exposición Zero Trust a Internet
            └── tasks/main.yml
```

---

## ⚙️ Requisitos Previos

### Software Necesario
- `terraform` (v1.0+)
- `ansible` y `ansible-playbook`
- `libvirt` / `qemu-kvm` activo en el Host
- `virsh` CLI

### Imagen Cloud de Ubuntu
Descargar la imagen Cloud de Ubuntu 22.04 (Jammy) en tu sistema:
```bash
/home/benja/Descargas/ISOs/jammy-server-cloudimg-amd64.img
```

---

## 🚀 Despliegue Automatizado

Para desplegar o recrear todo el laboratorio en un solo comando:

```bash
./reiniciarLanzar.sh
```

El script ejecutará automáticamente:
1. Destrucción limpia de instancias anteriores.
2. `terraform apply` parametrizado.
3. Actualización de IP en el inventario de Ansible.
4. Ejecución del playbook modular (`site.yml`).
5. Impresión de la **URL HTTPS Pública** generada por Cloudflare.

---

## 🧪 Comandos Manuales

### Terraform
```bash
# Inicializar proveedores
terraform init

# Validar sintaxis
terraform validate

# Planificar cambios
terraform plan

# Aplicar o destruir
terraform apply -auto-approve
terraform destroy -auto-approve
```

### Ansible
```bash
# Ejecutar playbook modular
ansible-playbook -i ansible/inventory.ini ansible/site.yml
```

---

## 🌐 Verificación y Acceso

### Acceso Local (LAN Host)
```bash
curl http://<vm_ip>
```

### Acceso Remoto desde cualquier lugar (Red Móvil 4G/5G)
Accede desde tu navegador o celular a la URL generada en la salida del rol `cloudflare`:
```text
https://xxxx.trycloudflare.com
```

---

## 🔒 Ventajas de la Arquitectura

* **Modularidad y Escalabilidad**: Separación clara de responsabilidades con variables en Terraform y Roles en Ansible.
* **Seguridad Zero Trust**: El servidor web no expone ningún puerto en el router doméstico.
* **Idempotencia**: Se puede recrear el entorno completo sin errores en menos de 60 segundos.
