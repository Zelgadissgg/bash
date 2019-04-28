#!/bin/bash

if [ -f "$(dirname $0)/../lib/case_common.sh" ];then
    source $(dirname $0)/../lib/case_common.sh
else
    exit $CR_ENVCHECK
fi
func_case_init

# invoke BATF framework already write the common function & framework common option
source $BATF_HOME/conf/framework_config.sh
source $BATF_FD_LIB/framework_common.sh

# user define function
# notice user define function must have return value
# because if you don't set the return value
# the last judgement/command will be catch by $?
FUNC_CASE_ENVCHECK="func_check_1"
FUNC_CASE_RESCHECK="func_check_2"
# this case for host only don't need upgrade base image
#FUNC_CASE_UPGIMAGE=""
FUNC_CASE_CLEANENV="func_clean_1"

# step define, should begin like this, because func_case_dump_description will scan it
FUNC_CASE_STEP_LST=(${FUNC_CASE_STEP_LST[*]} "func_step_1")
FUNC_CASE_STEP_LST=(${FUNC_CASE_STEP_LST[*]} "func_step_2")
FUNC_CASE_STEP_LST=(${FUNC_CASE_STEP_LST[*]} "func_step_3")

func_check_1()
{
    func_clean_1
    echo do some thing for your check step, please combine with test case document/case configure file
    echo meet some error return value in case_config.sh
    return $CR_PASS
}

func_step_1()
{
    echo "run step 1"
    return $CR_PASS
}

func_step_2()
{
    echo "run step 2"
    return $CR_PASS
}

func_define_other()
{
    echo "the other function"
}

func_clean_1()
{
    func_define_other
    echo 'test environment recover for next test case'
    return $CR_PASS
}

func_check_2()
{
    echo do some thing check after each step
    return $CR_PASS
}

func_step_3()
{
    echo "run step 3"
    return $CR_PASS
}

# invoke to run the test case
func_case_check_environments
func_case_run_process
func_case_finish $CR_PASS
