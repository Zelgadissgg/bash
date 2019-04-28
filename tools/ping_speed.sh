#!/bin/bash

declare -a target_lst
declare -A res_lst
tab_count=4
ping_count=10

target_lst=($(cat /etc/apt/sources.list.d/*.list /etc/apt/sources.list |grep deb|grep -v '#'|awk -F '/' '{print $3;}'|uniq))

echo Detect:
echo -n "name"
for i in $(seq 1 4)
do
    echo -ne "\t"
done
echo -e "count\tspend(sec)"
for i in ${target_lst[@]}
do
    echo -n $i
    num=$[ $tab_count * 8 - ${#i} ]
    while [ $num -gt 0 ]
    do
        echo -ne "\t"
        num=$[ $num - 8 ]
    done
    echo -ne "$ping_count\t"
    rt1=$(date +%s)
    res_lst["$i"]="$(ping -c $ping_count $i |sed -n '$p'|awk '{print $(NF -1);}')"
    rt2=$(date +%s)
    rt=$[ $rt2 - $rt1 ]
    echo "$rt"
done

echo -e "\nTest Report:"
echo -n "name"
for i in $(seq 1 4)
do
    echo -ne "\t"
done
echo -e "min\tavg\tmax\tmdev"
for i in ${target_lst[@]}
do
    echo -n $i
    num=$[ $tab_count * 8 - ${#i} ]
    while [ $num -gt 0 ]
    do
        echo -ne "\t"
        num=$[ $num - 8 ]
    done
    echo ${res_lst["$i"]}|sed 's:/:\t:g'
done

