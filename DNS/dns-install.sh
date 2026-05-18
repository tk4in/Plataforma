#!/bin/bash

echo -e "\n\e[32mCarrega as variáveis de configuração\e[0m"
mkdir -p /mnt/usb
mount -t vfat /dev/sdb1 /mnt/usb
export $(cat /mnt/usb/config.env | xargs)

if [ -z "$SSH_PORT" ] || [ -z "$DOM_VAL" ] || [ -z "$IP_VAL" ] || [ -z "$GW_VAL" ] || [ -z "$USER_VAL" ] || [ -z "$PASS_VAL" ]; then
   echo -e "O arquivo config.env não foi encontrado no pendrive ou falta alguma variável"
   echo -e "Verifique se o pendrive esta conectado e se o arquivo config.env existe."
   exit 1 # Sai do escript
fi

if [ -z "$dns1" ] && [ -z "$dns2" ]; then
   echo -e "Você deve informar o parâmetro --dns1 ou --dns2."
   exit 1
fi

echo -e "\n\e[32mInstalando dependencias\e[0m"
apk add ipcalc

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dns1)
            DNS_VAL="dns1"
            IP_MIN=$(ipcalc -n "$IP_VAL" | grep HostMin | awk '{print $2}')
            IFS=. read -r i1 i2 i3 i4 <<< "$IP_MIN"
            DNS_IP="$i1.$i2.$i3.$((i4 + 2))"
            ;;
        --dns2)
            DNS_VAL="dns2"
            IP_MIN=$(ipcalc -n "$IP_VAL" | grep HostMin | awk '{print $2}')
            IFS=. read -r i1 i2 i3 i4 <<< "$IP_MIN"
            DNS_IP="$i1.$i2.$i3.$((i4 + 3))"
            ;;
        *)
            echo -e "Você deve informar o parâmetro --dns1 ou --dns2."
            exit 1
            ;;
    esac
done

echo -e "${DNS_IP}"
