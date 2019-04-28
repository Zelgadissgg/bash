#!/bin/bash

set +o errexit
set +o errtrace
set +o functrace

[[ $UID -ne 0 ]] && echo "Please run $0 as root" && exit

func_check_cmd()
{
    which $1 2>/dev/null 1>/dev/null
    [[ $? -ne 0 ]] && exit
}

func_check_cmd dmidecode

tmp_file=/tmp/info_collect.$RANDOM

dmidecode -t baseboard > $tmp_file
[[ $(grep 'Name' $tmp_file |wc -l ) -gt 1 ]] && is_multi=1 || is_multi=0
cat << END
Hardware
    Borad
        Name        : $(awk -F ': ' '/Product/ {print $NF;}' $tmp_file)
        Version     : $(awk -F ': ' '/Version/ {print $NF;}' $tmp_file)
END


dmidecode -t processor > $tmp_file
[[ $(grep 'Name' $tmp_file |wc -l ) -gt 1 ]] && is_multi=1 || is_multi=0
cat << END
    CPU
        Name        : $(awk -F ': ' '/Version/ {print $NF;}' $tmp_file)
        Max Speed   : $(awk -F ': ' '/Max Speed/ {print $NF;}' $tmp_file)
        Core Enabled: $(awk -F ': ' '/Core Enabled/ {print $NF;}' $tmp_file)
        Thread Count: $(awk -F ': ' '/Thread Count/ {print $NF;}' $tmp_file)
END

dmidecode -t memory > $tmp_file
cat << END
    Memory
        Slot        : $(awk '/Number Of Devices/ {sum+=$NF} END {print sum;}' $tmp_file)
        Device Count: $(grep '^Memory Device' $tmp_file -c)
        Size        : $(awk -F ': ' '/Size: [1-9]/ {print $NF";";}' $tmp_file|tr -d [:cntrl:])
        Type        : $(awk -F ': ' '/Type: D/ {print $NF";";}' $tmp_file|tr -d [:cntrl:])
        Speed       : $(awk -F ': ' '/Speed: [1-9]/ {print $NF";";}' $tmp_file|tr -d [:cntrl:])
END

dmidecode -t bios > $tmp_file
cat << END
    BIOS
        Version    : $(awk -F ': ' '/Version/ {print $NF;}' $tmp_file)
END

# lspci device
func_check_cmd lspci
echo "    VGA"
for i in $(lspci |grep '[[:space:]]VGA compatible controller'|awk '{print $1;}')
do
    lspci -vmxs $i > $tmp_file
    cat << END
        Address    : $i
            Vendor : $(grep '^Vendor:[[:space:]][a-zA-Z]' $tmp_file|awk -F ':' '{print $NF;}' |tr -d [:cntrl:])
            Device : $(grep '^Device:[[:space:]][a-zA-Z]' $tmp_file|awk -F ':' '{print $NF;}' |tr -d [:cntrl:])
            Rev    : $(grep 'Rev:' $tmp_file|awk '{print $NF;}')
            PCI ID : $(grep '^00:' $tmp_file|awk '{print $5$4;}')
END
done

cat << END
Software
    Kernel
        Version     : $(uname -r)
        cmdline     : $(echo $(awk '{for(i=3;i<NF;i++) print $i;}' /proc/cmdline))
    OS
        Name        : $(awk -F '=' '/^ID=/ {print $NF;}' /etc/os-release)
        Version     : $(awk -F '=' '/^VERSION_ID=/ {print $NF;}' /etc/os-release)
END

rm $tmp_file -f
