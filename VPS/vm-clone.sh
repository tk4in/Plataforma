#!/bin/bash

helpFunction()
{
   echo -e "Use: $0 -t template -d dominio -p password"
   echo -e "\t-t Template da VM"
   echo -e "\t-d Dominio"
   echo -e "\t-p Senha do root"
   exit 1
}

while getopts t:d:p: opts; do
   case ${opts} in
      t) TEMP_VAL=${OPTARG} ;;
      d) DOM_VAL=${OPTARG} ;;
      p) PASS_VAL=${OPTARG} ;;
   esac
done

if [-z "$TEMP_VAL" ] || [-z "$DOM_VAL" ] || [ -z "$PASS_VAL" ]; then
   echo -e "\n\e[32mPreencha todos os parâmetros\e[0m";
   helpFunction.
fi

virt-clone --original $TEMP_VAL --name $TEMP_VAL-$DOM_VAL --auto-clone
chmod 664 /var/lib/libvirt/images/$TEMP_VAL-$DOM_VAL.qcow2
virt-sysprep -d $TEMP_VAL-$DOM_VAL --hostname $DOM_VAL --root-password password:$PASS_VAL
