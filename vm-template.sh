#!/bin/bash

sudo virt-install \
  --name $1-$2-$3-$4 \
  --vcpus $2 \
  --memory $3 \
  --disk path=/var/lib/libvirt/images/$1-$2-$3-$4.qcow2,size=$4,format=qcow2 \
  --location /var/lib/libvirt/images/$5 \
  --os-variant=$6 \
  --network network=default \
  --graphics none \
  --check all=off
  --console pty,target_type=serial \
  --initrd-inject /var/lib/libvirt/images/preseed.cfg \
  --extra-args="ks=file:/preseed.cfg console=tty0 console=ttyS0,115200n8"






#virsh domifaddr $1-$2-$3-$4

#virsh shutdown $1-$2-$3-$4
#virt-sysprep -d $1-$2-$3-$4 --hostname server
#virt-sparsify --compress \
#  /var/lib/libvirt/images/$1-$2-$3-$4.qcow2 \
#  /var/lib/libvirt/images/$1-$2-$3-$4.min.qcow2
#mv /var/lib/libvirt/images/$1-$2-$3-$4.min.qcow2 \
#  /var/lib/libvirt/images/$1-$2-$3-$4.qcow2
#chmod 444 /var/lib/libvirt/images/$1-$2-$3-$4.qcow2
