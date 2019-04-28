#!/bin/bash -x

cd $(dirname $0)
boot_full_name="$PWD/$(basename $0)"
cd $OLDPWD

boot_exec_file="/etc/rc.local"
[[ ! -f "$boot_exec_file"  ]] && echo "miss system, please update $boot_full_name" && exit

boot_once_flag=$(grep $(basename $0) $boot_exec_file -n)
boot_once_flag=${boot_once_flag/:*/}

if [ "$#" -ne 0 ];then
    # convert cmd to the cmd full path, because in the rc.local it just support PATH=/bin:/sbin:/usr/bin:/usr/sbin
    cmd_path=$(dirname $(which $1) 2>/dev/null)
    if [ "X${cmd_path/\/*/}" == "X." ];then #relative path
        cd $cmd_path
        cmd=$PWD/$(basename $1)
        cd $OLD_PATH
        shift
    elif [ "X${cmd_path:0:1}" == "X/" ]; then #absolute path
        cmd=$cmd_path/$(basename $1)
        shift
    elif [ "${type -t $(basename $1)}" == "builtin" ];then
        cmd=$(basename $1)
        shift
    else # Miss cmd_path means couldn't find this cmd in the path, so no change
        exit
    fi
    [[ ! "$boot_once_flag" ]] && echo $boot_full_name >> $boot_exec_file
    echo "$cmd $*" >> $boot_exec_file
else
    sed -i "$boot_once_flag,\$d" $boot_exec_file
fi

sed -i '/^exit/d' $boot_exec_file
echo "exit 0" >> $boot_exec_file
