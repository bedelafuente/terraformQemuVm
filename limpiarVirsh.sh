# Script que limpia virsh para evitar colisiones

virsh vol-delete commoninit.iso --pool default
virsh vol-delete UbuntuServer --pool default
virsh undefine ubuntu-server
virsh undefine UbuntuServer