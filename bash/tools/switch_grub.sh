#!/bin/bash

case $1 in
    *[!0-9]*)
        echo "Error SELECT value" ;;
    *)
        SELECT=$1;;
esac

#OS_NAME=$(grep '^ID=' /etc/os-release|sed 's/^ID=//g;s/"//g')
#OS_VER=$(grep '^VERSION_ID=' /etc/os-release|sed 's/^VERSION_ID=//g;s/"//g')
#case $OS_NAME in
#    "ubuntu"|"fedora"|"centos"|"rhel")
#        echo Current OS: $OS_NAME $OS_VER is supported
#    ;;
#    *) echo "error system detect: $OS_NAME" && exit ;;
#esac

declare -a ENTRY_LST
declare -A ADV_ENTRY_LST

GRUB_FILE=$(find /boot -name grub.cfg)
GRUB_FD=$(dirname $GRUB_FILE)
CURRENT_BOOT=$(grep 'default=' $GRUB_FILE|grep -v '#'|grep -v 'next'|awk -F '"' '{print $2;}')
GRUB_IDX=0
[[ "${CURRENT_BOOT:0:4}" == "save" ]] && SAVE_ENTRY=1 || SAVE_ENTRY=0
if [ $SAVE_ENTRY -eq 1 ];then
    CURRENT_BOOT=$(awk -F '=' '/entry=/ {print $2;}' $GRUB_FD/grubenv)
    func_modify_boot()
    {
        grub2-set-default "${ADV_ENTRY_LST[${ENTRY_LST[$1]}]}"
    }
else
    func_modify_boot()
    {
        sed -i "s:default=\"$CURRENT_BOOT\":default=\"${ENTRY_LST[$1]}\":g" $GRUB_FILE
    }
fi

func_catch_entry()
{
    local line grub_entry_file=/tmp/$RANDOM.grub idx=0 sub_idx=0
    grep 'menu.*{$' $GRUB_FILE|grep -v '#' > $grub_entry_file
    [[ -f $CUSTOM_FILE ]] && grep 'menu.*{$' $CUSTOM_FILE|grep -v '#' >> $grub_entry_file
    local line_count=$(wc -l $grub_entry_file|awk '{print $1;}') line_idx entry_idx
    for line_idx in $(seq 1 $line_count)
    do
        line=$(sed -n "$line_idx""p" $grub_entry_file)
        # submenu is not effect boot menu, so skip it
        [[ "${line:0:3}" == "sub" ]] && sub_idx=0 && continue
        # now enter for the submenu configure
        if [ "${line:1:4}" == "menu" ];then
            entry_idx="$idx>$sub_idx"
            sub_idx=$[ $sub_idx + 1 ]
        else
            entry_idx="$idx"
            idx=$[ $idx + 1 ]
        fi
        ADV_ENTRY_LST[$entry_idx]=$(echo $line|awk -F "'" '{print $2;}')
        ENTRY_LST=("${ENTRY_LST[@]}" "$entry_idx")
    done
    rm -rf $grub_entry_file
}

func_dump_boot()
{
    local i sel
    for (( i=0; i<${#ENTRY_LST[@]}; i++))
    do
        sel=0
        if [ "$1" ];then
            #[[ "$i" == "$1" ]] && sel=1
            [[ "${ENTRY_LST[$i]}" == "$1" ]] && sel=1
            [[ "${ADV_ENTRY_LST[${ENTRY_LST[$i]}]}" == "$1" ]] && sel=1
        fi
        [[ $sel -eq 1 ]] && GRUB_IDX=$i && echo -ne "\033[31m"
        echo "$i"". ""${ADV_ENTRY_LST[${ENTRY_LST[$i]}]}"
        [[ $sel -eq 1 ]] && echo -ne "\033[0m"
    done
}

func_catch_entry
func_dump_boot "$CURRENT_BOOT"
if [ "$SELECT" ];then
    for (( i=0; i<${#ENTRY_LST[@]}; i++))
    do
        [[ $i -eq $SELECT ]] && func_modify_boot $i && GRUB_IDX=$i && break
    done

    [[ $i -ge ${#ENTRY_LST[@]} ]] && \
        echo -ne "\nGrub order \033[31m$SELECT\033[0m is not effective value\n" && \
        SELECT="$CURRENT_BOOT" || \
        SELECT="${ENTRY_LST[$SELECT]}"
    echo -e "\nAfter Grub order change current grub boot:\n"
    func_dump_boot "$SELECT"
else
    echo "$GRUB_IDX"
    exit $GRUB_IDX
fi
