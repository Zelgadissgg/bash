#!/bin/bash

cd $(dirname $0)
WORK_DIR=$PWD
BATF_HOME="/batf"
source framework/framework_common.sh
source framework/framework_config.sh

FUNC_STEP_LST=(${FUNC_STEP_LST[*]} "func_install_software")
FUNC_STEP_LST=(${FUNC_STEP_LST[*]} "func_publish_framework")

func_install_software()
{
    local i
    func_batf_os_info
    [[ ! -d $WORK_DIR/install ]] && return 0
    for i in $WORK_DIR/install/*
    do
        $i
    done
}

func_publish_framework()
{
    mkdir $BATF_HOME
    local fd_name
    for fd_name in $BATF_FD_LST[*]
    do
        fd_name=$(basename $fd_name)
        [[ -d $fd_name ]] && cp $fd_name $BATF_HOME/$fd_name -rf || mkdir -p $BATF_HOME/$fd_name
    done
}

# force run function
for i in ${FUNC_STEP_LST[@]}
do
    $i
done
