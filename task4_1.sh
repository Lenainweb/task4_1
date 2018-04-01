#!/bin/bash

# Redirecting output to a file
exec >task4_1.out

echo "--- Hardware ---"
# Gathering information about the equipment of the device
echo "CPU: $(cat /proc/cpuinfo | grep -m 1 'model name' | sed 's/model name//' | sed 's/: //' | sed 's/\t//' )"
echo "RAM: $(cat /proc/meminfo | grep 'MemTotal' | sed 's/MemTotal//' | tr -d ':' | tr -d ' '| tr '[:lower:]' '[:upper:]') "

# Checking the availability of data on the motherboard
if [ "$(dmidecode -q -s baseboard-manufacturer)" ] ; then
    manufacture=$(dmidecode -s baseboard-manufacturer)
else
    manufacture=Unknown
fi
if [ "$(dmidecode -s baseboard-product-name)" ] ; then
    product_name=$(dmidecode -s baseboard-product-name)
else
    product_name=Unknown
fi
# Checking the availability of data on the serial number 
if [[ $(dmidecode -q -s system-serial-number) = 'To Be Filled By O.E.M.' ]];then
    serial_num=Unknown
elif [ $? != 0 ] ; then
    if [ ! -e /sys/devices/virtual/dmi/id/product_serial ] ; then
        serial_num=Unknown
    elif  grep -s -q 'To Be Filled By O.E.M.' /sys/devices/virtual/dmi/id/product_serial ; then
        serial_num=Unknown
    else serial_num=$(cat /sys/devices/virtual/dmi/id/product_serial)
    fi
else
    serial_num=$( dmidecode -q -s system-serial-number) 
fi

echo "Motherboard: $manufacture $product_name" 
echo "System Serial Number: $serial_num"

echo "--- System ---"
# Collect information about the operating system 
echo "OS Distribution: $(cat /etc/*-release | grep -m 1 'PRETTY_NAME' | sed 's/PRETTY_NAME=//'| sed 's/"//' | sed 's/"//')"
echo "Kernel version: $(uname -r)" 

# Check the operating system installation date
date_lsb=$(stat -c%z /etc/lsb-release | cut -c -19)
date_os=$(stat -c%z /etc/os-release | cut -c -19)
if [ "$date_lsb" = "$date_os" ]; then
    instal_date=$date_lsb
else
    instal_date=Unknown
fi
echo "Installation date: $instal_date" 
echo "Hostname: $HOSTNAME"
echo "Uptime: $(uptime -p | sed 's/up //')"
processes=$(ps -e | wc -l)
processes=$(($processes-1))
echo "Processes running: $processes"
echo "User logged in: $(who -q | grep '=' | sed 's/=/ /' | awk ' {print $3} ')"

echo "--- Network ---"
# Collecting information about network interfaces
declare -a namenet
i=0
# Finds the name of the device Находит название устройств
for word in $(ip address | awk -F': '  ' {print $2} ')
    do
    namenet[$i]=$word
    ((i ++))
done
i=0
# Finds addresses 
for word in "${namenet[@]}"
    do
    addressnet[$i]="$word:"
    
    if ! [ -z $( echo $word | grep -m 1 '@' ) ] ; then
        word=$( echo $word | grep -m 1 '@' | sed 's/@/ /' | awk '{print $1}' )
    fi
    # Checks for IP4
    if [ -z $( ip address show $word | grep -T 'inet '| awk '{print $2}' ) ] ; then
        addressnet[$i]=${addressnet[i]}' -'
    fi
    # By name search all IP4
    j=0
    for numip in $( ip address show $word | grep -T 'inet '| awk '{print $2}' )
        do
        addressnet[$i]=${addressnet[i]}' '${numip}
        if [[ $j > 0 ]] ; then
            addressnet[$i]=${addressnet[i]}','
        ((j ++))
        fi
    done
    ((i ++))
done

for addressline  in "${addressnet[@]}"
    do
    echo "$addressline"
done

if [ -e task4_1.out ] ; then
    exit 0
fi
exit 1

