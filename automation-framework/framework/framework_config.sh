#!/bin/bash
# force check for protect script integrity
[[ ! "$BATF_HOME" ]] && exit

# framework folder list define
declare -xgA BATF_FD_LST
BATF_FD_LST['case']="$BATF_HOME/case"
BATF_FD_LST['conf']="$BATF_HOME/conf"
BATF_FD_LST['lib']="$BATF_HOME/framework"
BATF_FD_LST['plugin']="$BATF_HOME/plugin"
BATF_FD_LST['report']="$BATF_HOME/report"
BATF_FD_LST['tmp']="/tmp/batf"
BATF_FD_LST['template']="$BATF_HOME/template"
BATF_FD_LST['tools']="$BATF_HOME/tools"
BATF_FD_LST['envcheck']="$BATF_HOME/envcheck"

# alias name to quickly load
declare -xgr BATF_FD_CASE=${BATF_FD_LST['case']}
declare -xgr BATF_FD_CONF=${BATF_FD_LST['conf']}
declare -xgr BATF_FD_LIB=${BATF_FD_LST['lib']}
declare -xgr BATF_FD_PLUGIN=${BATF_FD_LST['plugin']}
declare -xgr BATF_FD_REPORT=${BATF_FD_LST['report']}
declare -xgr BATF_FD_TMP=${BATF_FD_LST['tmp']}
declare -xgr BATF_FD_TMPL=${BATF_FD_LST['template']}
declare -xgr BATF_FD_TOOLS=${BATF_FD_LST['tools']}
declare -xgr BATF_FD_ENVCHECK=${BATF_FD_LST['envcheck']}

# framework define
# open debug call trace function
declare -xg BATF_DEBUG=1

# framework log define
declare -xg BATF_REPORT_HOME=""
declare -xg BATF_SUMMARY_FILE=""

# setup tools &debug-tools to the run path
export PATH=$BATF_FD_TOOLS:$PATH

# framework function define for protect script integrity
declare -xga BATF_FUNC_LST

# test case list
declare -xga BATF_CASE_LST

# OS information
decclare -xg OS_NAME OS_VERSION
