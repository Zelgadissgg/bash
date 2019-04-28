#!/bin/bash

set +o errexit
set +o errtrace
set +o functrace

[[ -d "/batf" ]] && BATF_HOME="/batf"
if [[ ! "$BATF_HOME" ]];then
    cd $(dirname $0)
    BATF_HOME=$PWD
fi

export BATF_HOME

[[ ! -f $BATF_HOME/lib/framework_common.sh ]] && \
    echo "Miss framework lib file at $BATF_HOME/lib/framework_common.sh, please check it" && \
    exit 3
source $BATF_HOME/lib/framework_common.sh

func_batf_init
func_batf_check_enviroments
func_batf_scan_case
func_batf_run_case
func_batf_deal_result
