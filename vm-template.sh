#!/bin/bash

virt-install \
  --name $1-$2-$3-$4 \
  --vcpus $2 \
  --memory $3 \
  --disk path=/var/lib/libvirt/images/$1-$2-$3-$4.qcow2,size=$4 ,format=qcow2 \
  --location /var/lib/libvirt/images/$5 \
  --os-variant=$6 \
  --network network=default \
  --graphics none \
  --console pty,target_type=serial \
  --extra-args='console=ttyS0,115200n8'
