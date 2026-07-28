#!/bin/bash
# Script que reinicia y lanza de nuevo el proyecto xd

set -e

echo "Paso 1: Forzando apagado de la VM si está corriendo..."
virsh destroy ubuntu-vm 2>/dev/null && echo "   VM apagada." || echo "   VM ya estaba apagada."

echo "Paso 2: Destruyendo infraestructura con Terraform..."
terraform destroy -auto-approve

echo "Paso 3: Creando infraestructura nueva con Terraform..."
terraform apply -auto-approve

IP_MaquinaVirtual=$(terraform output -raw vm_ip)

echo "Paso 4: Cambiando IP en el inventario..."

sed -i "s/ansible_host=[0-9.]*/ansible_host=$IP_MaquinaVirtual/" ansible/inventory.ini

echo "Paso 5: Esperando que SSH esté disponible en la VM..."
# La VM necesita ~30s para arrancar y que el servicio SSH quede listo.
sleep 45

echo "Paso 6: Ejecutando Ansible (instala Nginx y despliega la web)..."
ansible-playbook -i ansible/inventory.ini ansible/site.yml

echo ""
echo "✅ Listo. Nueva IP:"
# Imprime solo el valor de la IP, sin decoración extra de Terraform.
terraform output vm_ip