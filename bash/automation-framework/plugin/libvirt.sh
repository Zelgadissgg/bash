#!/bin/bash

declare -xgi PLUGIN_LIBVIRT_MAX_GUEST
declare -a PLUGIN_LIBVIRT_MAC_LST
declare -a PLUGIN_LIBVIRT_IP_LST

declare -xf func_plugin_libvirt_init

function func_plugin_libvirt_init()
{
    [[ -f $BATF_FD_PLUGIN/conf/libvirt.sh ]] && source $BATF_FD_PLUGIN/conf/libvirt.sh
    PLUGIN_LIBVIRT_MAX_GUEST=${max_guest:-253}
    [[ $PLUGIN_LIBVIRT_MAX_GUEST -gt 253 ]] && PLUGIN_LIBVIRT_MAX_GUEST=253
    mkdir -p $BATF_FD_TMPL/libvirt
    # create mac -> ip mapping logic
    [[ ! -f $BATF_FD_TMPL/libvirt/default.xml ]] && virsh net-dumpxml default > $BATF_FD_TMPL/libvirt/default.xml
    virsh net-dumpxml default > $BATF_TMP/libvirt.xml
    xml2 < $BATF_TMP/libvirt.xml > $BATF_TMP/libvirt.txt
    func_libvirt_create_mac
    unset func_libvirt_create_mac
    func_libvirt_register_ip
    unset func_libvirt_register_ip
    2xml < $BATF_TMP/libvirt.txt > $BATF_TMP/libvirt.xml
    virsh net-destroy default
    virsh net-undefine default
    virsh net-define $BATF_TMP/libvirt.xml
    virsh net-start default
    mv $BATF_TMP/libvirt.xml $BATF_FD_TMPL/libvirt/current.xml
    rm -rf $BATF_TMP/libvirt.txt
}

function func_libvirt_create_mac()
{
    # because libvirt create bridge also have the mac address
    local -i mac_count=$[ $PLUGIN_LIBVIRT_MAX_GUEST + 1 ]
    [[ ! -f $BATF_FD_TMPL/libvirt/mac ]] && > $BATF_FD_TMPL/libvirt/mac
    awk -F '=' '/mac\/@address/ {print $NF;}' $BATF_TMP/libvirt.txt > $BATF_FD_TMPL/libvirt/mac
    local -i count=$(grep "mac/@address" $BATF_TMP/libvirt.txt -c)
    local macaddr
    while [ $count -lt $mac_count ]
    do
        # libvirt define QEMU virtual machines it should be start with '52:54:00'
        macaddr=$(echo "525400$(printf %02x $[ $RANDOM / 16 / 16 ])$(printf %04x $RANDOM)"|sed 's/../&:/g;s/:$//g')
        [[ $(grep "$macaddr" $BATF_FD_TMPL/libvirt/mac) ]] && continue
        echo "$macaddr" >> $BATF_FD_TMPL/libvirt/mac
        count=$(grep '^52:54:00' $BATF_FD_TMPL/libvirt/mac -c)
    done
    PLUGIN_LIBVIRT_MAC_LST=($(cat $BATF_FD_TMPL/libvirt/mac))
}

function func_libvirt_register_ip()
{
    local -i ip_count=$[ $PLUGIN_LIBVIRT_MAX_GUEST + 1 ]
    [[ ! -f $BATF_FD_TMPL/libvirt/ip ]] && > $BATF_FD_TMPL/libvirt/ip
    # dump libvirt ip setting
    awk -F '=' '/ip\/@address/ {print $NF;}' $BATF_TMP/libvirt.txt > $BATF_FD_TMPL/libvirt/ip
    netmask=$(awk -F '=' '/netmask/ {print $2;}' $BATF_TMP/libvirt.txt |head -n 1)
    ip_addr=$(awk -F '=' '/range\/@start/ {print $2;}' $BATF_TMP/libvirt.txt)
    ip_scope=${ip_addr%.*}
    local -i count=$(grep "^$ip_scope" $BATF_FD_TMPL/libvirt/ip -c)
    # .0 is no effect, .1 ready for bridge
    cur_addr=$[ ${ip_addr##*.} + $count - 1 ]
    while [ $count -lt $ip_count ]
    do
        # ip already in the libvirt.xml
        if [ ! $(grep "${PLUGIN_LIBVIRT_MAC_LST[$count]}" $BATF_TMP/libvirt.txt) ];then
            cat << END >> $BATF_TMP/libvirt.txt
/network/ip/dhcp/host
/network/ip/dhcp/host/@mac=${PLUGIN_LIBVIRT_MAC_LST[$count]}
/network/ip/dhcp/host/@ip=$ip_scope.$cur_addr
END
            echo "$ip_scope.$cur_addr" >> $BATF_FD_TMPL/libvirt/ip
        fi
        count=$(grep "^$ip_scope" $BATF_FD_TMPL/libvirt/ip -c)
        cur_addr=$[ ${ip_addr##*.} + $count - 1 ]
    done
    sed -i "s:@start=$ip_addr:@start=$ip_scope.$cur_addr:g" $BATF_TMP/libvirt.txt
    PLUGIN_LIBVIRT_IP_LST=($(cat $BATF_FD_TMPL/libvirt/ip))
}
