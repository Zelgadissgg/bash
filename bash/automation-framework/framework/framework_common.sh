#!/bin/bash

#$ The logic of function define in framework_common
#$ Main process
#$ func_batf_init
#$      func_batf_import_setting
#$      func_batf_create_report
#$      func_batf_load_plugin
#$          func_plugin_xxx_init
#$ 
#$ func_batf_check_environments
#$      func_plugin_xxx_check_environments
#$
#$ func_batf_scan_case
#$
#$ func_batf_run_case
#$
#$ func_batf_deal_result
#$
#$ function description
#$ func_batf_init()
#$      # test framework automation initialization environment
#$ func_batf_import_setting()
#$      # framework configure import
#$ func_batf_create_report()
#$      # framework to create the test report folder
#$ func_batf_load_plugin()
#$      # framework load plugin
#$ func_batf_check_enviroments()
#$      # framework check the environment by common
#$ func_batf_scan_case()
#$      # framework scan for effect case
#$ func_batf_run_case()
#$      # framework to run all test case
#$ func_batf_deal_result()
#$      # framework to deal the test-report
#$ func_batf_interrupt_cmd()
#$      # recover the case interrupt command
#$ func_batf_resume_cmd()
#$      # resume the command by case interrupt
#$ func_batf_verfiy_percase()
#$      # detect the test case Preconditions record test case result
#$ func_batf_os_info()
#$      # detect the OS information


# force check for protect script integrity
[[ ! "$BATF_HOME" ]] && exit

BATF_FUNC_LST=(${BATF_FUNC_LST[*]} "func_batf_init")
BATF_FUNC_LST=(${BATF_FUNC_LST[*]} "func_batf_import_setting")
BATF_FUNC_LST=(${BATF_FUNC_LST[*]} "func_batf_create_report")
BATF_FUNC_LST=(${BATF_FUNC_LST[*]} "func_batf_load_plugin")
BATF_FUNC_LST=(${BATF_FUNC_LST[*]} "func_batf_check_enviroments")
BATF_FUNC_LST=(${BATF_FUNC_LST[*]} "func_batf_scan_case")
BATF_FUNC_LST=(${BATF_FUNC_LST[*]} "func_batf_run_case")
BATF_FUNC_LST=(${BATF_FUNC_LST[*]} "func_batf_deal_result")
BATF_FUNC_LST=(${BATF_FUNC_LST[*]} "func_batf_interrupt_cmd")
BATF_FUNC_LST=(${BATF_FUNC_LST[*]} "func_batf_resume_cmd")
BATF_FUNC_LST=(${BATF_FUNC_LST[*]} "func_batf_vierfy_percase")

declare -xf ${BATF_FUNC_LST[*]}

function func_batf_debug_call_trace()
{
    [[ "X$BATF_DEBUG" != "X1" ]] && return
    local idx=0
    for (( idx=${#FUNCNAME[*]}-1 ; idx>=0; idx-- ))
    do
        echo -e "${BASH_SOURCE[$idx]}:${BASH_LINENO[$idx]}\t${FUNCNAME[$idx]}"
    done
}

function func_batf_check_environments()
{
    _func_env_check_error()
    {
        echo -e "\n\n$BATF_SPLIT_LINE\nplease run this script $1"
        func_batf_debug_call_trace && exit 3
    }

    # check user is root
    echo checking the current user......
    [[ $UID -ne 0 ]] && _func_env_check_error "as root"
    echo -e "current user is $USER\n"

    # environment check
    if [[ -d $BATF_FD_ENVCHECK ]];then
        if [[ "$(ls $BATF_FD_ENVCHECK)" ]];then
            local envcheck
            for envcheck in $BATF_FD_ENVCHECK/*
            do
                $envcheck
                [[ $? -ne 0 ]] && _func_env_check_error "pass $envcheck return 0"
            done
        fi
    fi

    local plugin
    for plugin in $BATF_FD_PLUGIN/*
    do
        source $plugin
        plugin=$(basename $plugin)
        plugin=${plugin/\.sh/}
        [[ type -t "func_plugin_"$plugin"_check_environments" == "function" ]] && "func_plugin_"$plugin"_check_environments"
    done
    unset _func_env_check_error
}

function func_batf_interrupt_cmd()
{
    if [ -f $BATF_FD_TMPL/cmd/$1 ];then
        source $BATF_FD_TMPL/cmd/$1
        export -f $1
    fi
}

function func_batf_resume_cmd()
{
    if [ $(type -t $1) == "function" ];then
        type -a $1 |grep -v '[[:space:]]is[[:space:]]' > $BATF_FD_TMPL/cmd/$1
        unset $1
    fi
}

function func_batf_verfiy_percase()
{
    local case_name
    for case_name in $*
    do
        [[ $(awk -F ',' "/$case_name,/ {print \$3;}" $BATF_SUMMARY_FILE) != "PASS" ]] && return 1
    done
    return 0
}

function func_batf_init()
{
    func_batf_import_setting
    mkdir -p ${BATF_FD_LST[*]}
    func_batf_create_report
}

function func_batf_import_setting()
{
    [[ ! -f $BATF_HOME/framework/framework_config.sh ]] && echo "Miss framework configure file, framework quit" && exit
    source $BATF_HOME/framework/framework_config.sh
}

function func_batf_write_report_title()
{
    cat << END >> $1
id,name,result,type,count,total,average
END
}

function func_batf_create_report()
{
    BATF_REPORT_HOME="$BATF_FD_REPORT/$(date +%Y-%m-%d)"
    BATF_REPORT_HOME="$BATF_REPORT_HOME/$(date +%H-%M-%S)"
    mkdir -p $BATF_REPORT_HOME
    cd $(dirname $BATF_REPORT_HOME)
    [[ -f current ]] && rm -rf current
    ln -s $(basename $BATF_REPORT_HOME) current
    cd $OLDPWD
    func_batf_write_report_title $BATF_REPORT_HOME/summary.csv
}

function func_batf_load_plugin()
{
    local plugin
    for plugin in $BATF_FD_PLUGIN/*
    do
        source $plugin
        plugin=$(basename $plugin)
        plugin=${plugin/\.sh/}
        type -t "func_plugin_"$plugin"_init" 2>/dev/null
        [[ ! "$(type -t "func_plugin_"$plugin"_init")" ]] && \
            echo -e "In $BATF_FD_PLUGIN/plugin $plugin or $plugin.sh file should have func_plugin_"$plugin"_init function\nError of load plugin" && \
            exit
        [[ type -t "func_plugin_"$plugin"_init" == "function" ]] && "func_plugin_"$plugin"_init"
    done
}

function func_batf_scan_case()
{
    [[ ! -d $BATF_FD_CASE ]] && echo "Miss test case at $BATF_FD_CASE folder"
    cd $BATF_FD_CASE
    BATF_CASE_LST=($(ls -v [1-9]*.*))
    cd $OLDPWD
}

function func_batf_run_case()
{
    local test_case workdir=$PWD
    for test_case in ${BATF_CASE_LST[*]}
    do
        cd $workdir
        $BATF_FD_CASE/$test_case
    done
}

function func_batf_deal_result()
{
    echo TODO
}

function func_batf_os_info()
{
    [[ -f /etc/os-release ]] && \
        OS_NAME=$(awk -F '=' '/^ID=/ {print $2;}' /etc/os-release) || \
        OS_NAME=$(awk -F '=' '/^ID=/ {print $2;}' /usr/lib/os-release)

    [[ -f /etc/os-release ]] && \
        OS_VERSION=$(awk -F '[="]' '/^VERSION_ID=/ {print $NF;}' /etc/os-release) || \
        OS_VERSION=$(awk -F '[="]' '/^VERSION_ID=/ {print $NF;}' /usr/lib/os-release)

    if [ "X$OS_VERSION" = 'X"' ];then
        [[ -f /etc/os-release ]] && \
            OS_VERSION=$(awk -F '[="]' '/^VERSION_ID=/ {print $(NF-1);}' /etc/os-release) || \
            OS_VERSION=$(awk -F '[="]' '/^VERSION_ID=/ {print $(NF-1);}' /usr/lib/os-release)
    fi
}
