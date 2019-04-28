#!/bin/bash

# case status define

# case result status define
# pass->0; fail->1; block other case->2; envcheck failed->3; case define error->5
declare -xgr CR_PASS=0 CR_FAILED=1 CR_BLOCK=2 CR_ENVCHECK=3 CR_CASE=4
# case type status define
# function->1 stress->2 undefine case type -> 0
declare -xgr CT_UNKNOW=0 CT_FUN=1 CT_STRESS=2

#$
#$ user API & OPTION rewrite location
#$ BEGIN
#$

# user define environment check function
declare -xg FUNC_CASE_ENVCHECK=''
# user define test result check function after each step to check result
# for example: after each step to check dmesg log/system log
declare -xg FUNC_CASE_RESCHECK=''
# user define update image to check this case need run test-app in guest os
declare -xg FUNC_CASE_UPGIMAGE=''
# user define clean environment to restore test environemnt
declare -xg FUNC_CASE_CLEANENV=''

# test case run step
declare -xga FUNC_CASE_STEP_LST

# Test case run type, default is unknow
declare -xg CASE_TYPE=${CASE_TYPE:-0}
# Case type is function run count means loop count
# Case type is stress run stress time, unit is h
declare -xg CASE_RUN_COUNT=${CASE_RUN_COUNT:-1}

#$
#$ END
#$ user API & OPTION rewrite location
#$

# define whether test case load from framework
declare -xg CASE_FROM_FRAMEWORK={$CASE_FROM_FRAMEWORK:-0}

# define whether send mail report
declare -xg CASE_SEND_MAIL={$CASE_SEND_MAIL:-0}

# test case whether write the log
declare -xg CASE_WRITE_LOG=${CASE_WRITE_LOG:-1}

# test report log file
declare -xg CASE_LOG_PATH=${CASE_SUMMARY_FILE:-''}
declare -xg CASE_SUMMARY_FILE=${CASE_SUMMARY_FILE:-''}
declare -xg CASE_PROCESS_FILE=${CASE_PROCESS_FILE:-''}

# define detect case name & store case result
declare -xg CASE_ID=${CASE_ID:-''}
declare -xg CASE_NAME=${CASE_NAME:-''}
declare -xg CASE_RESULT=${CASE_RESULT:-1}
declare -xg CASE_CONF=${CASE_CONF:-''}

# define case run time
declare -xg CASE_START_TIME=0
# average run time of loop
declare -xg CASE_TIME_AVERAGE=0
# total run time of loop
declare -xg CASE_TIME_TOTAL=0

# test case function define for protect script integrity
declare -xga CASE_FUNC_LST
