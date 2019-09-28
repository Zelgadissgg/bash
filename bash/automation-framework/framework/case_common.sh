#!/bin/bash

#$ The logic of function define in case_common
#$ Main process
#$ func_case_init
#$      func_case_get_casename
#$      func_case_get_reportname
#$      func_case_import_setting
#$      func_case_interrupt_cmd
#$      func_case_verify_type
#$      
#$ func_case_check_environments
#$        func_batf_check_environments
#$      func_case_dump_description
#$      FUNC_CASE_UPGIMAGE
#$      FUNC_CASE_ENVCHECK
#$
#$ func_case_run_process
#$      func_case_run_stress
#$          FUNC_CASE_STEP_LST
#$          FUNC_CASE_RESCHECK
#$      OR
#$      func_case_run_loop
#$          FUNC_CASE_STEP_LST
#$          FUNC_CASE_RESCHECK
#$
#$ func_case_finish()
#$      func_case_send_mail
#$          func_case_package_result
#$
#$ function description
#$ func_case_init() 
#$      # test case automation initialization environment for get
#$      # who(framework/other) load this case
#$ func_case_check_environments()
#$      # environment check precondition mapping the document 
#$ func_case_run_process()
#$      # test case run process, should load for each test step
#$ func_case_finish()
#$      # test case finish step, instead of exit
#$      # intercept exit
#$ func_case_get_casename()
#$      # get current test case name
#$ func_case_get_reportname()
#$      # get current test case test report name
#$ func_case_dump_description()
#$      # output case description from case configure & case realize script
#$ func_case_output()
#$      # control test case output, instead of echo
#$      # intercept echo
#$ func_case_send_mail()
#$      # send mail format report
#$ func_case_package_result()
#$      # compress test report folder for mail send
#$ func_case_run_stress()
#$      # run test case by time limit when CASE_TYPE is CT_STRESS
#$ func_case_run_loop()
#$      # run test case by loop when when CASE_TYPE is CT_FUN
#$ func_case_write_summary_format_title()
#$      # write summary format title
#$ func_case_write_summary_format_result()
#$      # write mail format title
#$ func_case_verify_type()
#$      # case define value verify
#$ func_case_import_setting()
#$      # case configure import
#$ func_case_interrupt_cmd()
#$      # case interrupt_cmd
#$      # intercept shell builtin command
#$          # exit -> func_case_finish
#$          # echo -> func_case_output

CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_init")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_check_environments")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_run_process")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_finish")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_get_casename")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_get_reportname")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_dump_description")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_output")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_send_mail")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_package_result")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_run_stress")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_run_loop")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_write_summary_format_title")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_write_summary_format_result")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_verify_type")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_import_setting")
CASE_FUNC_LST=(${CASE_FUNC_LST[*]} "func_case_interrupt_cmd")

declare -xf ${CASE_FUNC_LST[*]}

function func_case_init()
{
    if [ ! "$BATF_HOME" ];then
        CASE_FROM_FRAMEWORK=0
        # analyze for detect BATF_HOME
        cd $(dirname $0)/../
        BATF_HOME=$PWD
        cd $OLDPWD
        # Now run the percheck which should run by framework, but when you direct run the case, it should run by it self
        export BATF_HOME
        # import framwork setting
        source $BATF_HOME/framework/framework_common.sh
        func_batf_init
    else
        CASE_FROM_FRAMEWORK=1
    fi
    func_case_get_casename
    func_case_import_setting
    func_case_get_reportname
    func_case_interrupt_cmd
    func_case_verify_type
}

function func_case_finish()
{
    # convert case exit status to human read style
    case $1 in
        $CR_PASS)     CASE_RESULT='PASS' ;;
        $CR_FAILED)   CASE_RESULT='FAIL' ;;
        $CR_BLOCK)    CASE_RESULT='BLOCK' ;;
        $CR_ENVCHECK) CASE_RESULT='NRUN' ;;
        $CR_CASE)     CASE_RESULT='CaseInputError' ;;
        $CR_CASE)     CASE_RESULT='CaseDefineError' ;;
        *)            CASE_RESULT='UNDEFINE' ;;
    esac
    # get case run time
    if [ "X$CASE_START_TIME" != "X0" -a "X$CASE_TIME_TOTAL" == "X0" ];then
        CASE_TIME_TOTAL=$[ $(date +%s) - $CASE_START_TIME ]
    fi
    # dump error call trace for case debug option
    if [ "X$1" != "X0" ];then
        local idx=0
        for (( idx=${#FUNCNAME[*]}-1 ; idx>=0; idx-- ))
        do
            echo -e "${BASH_SOURCE[$idx]}:${BASH_LINENO[$idx]}\t${FUNCNAME[$idx]}"
        done
    fi
    # run environment clear function, this function ignore the error message
    [[ "$(type -t $FUNC_CASE_CLEANENV)" == "function" ]] && $FUNC_CASE_CLEANENV
    # convert case type status to human read style
    case $CASE_TYPE in
        $CT_FUN)
            CASE_TYPE='Function'
            if [ $CASE_TIME_TOTAL -ne 0 ];then
                CASE_TIME_AVERAGE=$[ $CASE_TIME_TOTAL / $CASE_RUN_COUNT ]
            fi
            ;;
        $CT_STRESS)
            CASE_TYPE='Stess'
            CASE_RUN_COUNT=$CASE_RUN_COUNT" hour"
            ;;
        *)
            CASE_TYPE='unknow'
            ;;
    esac
    func_batf_resume_cmd echo
    CASE_TIME_TOTAL="$(convert_time.sh $CASE_TIME_TOTAL)"
    CASE_TIME_AVERAGE="$(convert_time.sh $CASE_TIME_AVERAGE)"
    [[ "$CASE_SUMMARY_FILE" ]] && func_case_write_summary_format_result $CASE_SUMMARY_FILE
    func_case_send_mail
    cat << END
Case id: $CASE_ID 
    Name: $CASE_NAME
    Result: $CASE_RESULT
    Type: $CASE_TYPE
    Count: $CASE_RUN_COUNT
    Runtime:
        Total: $CASE_TIME_TOTAL
        Average:$CASE_TIME_AVERAGE
END
    func_batf_resume_cmd exit
    exit $1
}

function func_case_run_process()
{
    # force run function
    local step_result=0 step i time_start time_end

    for step in ${FUNC_CASE_STEP_LST[@]}
    do
        if [ "$(type -t $step)" != "function" ];then
            echo "step check before run: $step should be the same name function"
            exit $CR_CASE
        fi
    done

    CASE_START_TIME=$(date +%s)
    case $CASE_TYPE in
        $CT_FUN)     func_case_run_loop ;;
        $CT_STRESS)  func_case_run_stress ;;
        *)
            echo "$CASE_NAME: configure error to block run the test case"
            exit $CR_CASE  ;;
    esac
    CASE_TIME_TOTAL=$[ $(date +%s) - $CASE_START_TIME ]
}

export -f func_case_init func_case_run_process func_case_finish

###########################################################
##
## internal function
##
###########################################################

function func_case_verify_type()
{
    if [ "X$CASE_TYPE" != "X$CT_UNKNOW" ];then
        if [ "X$CASE_TYPE" != "X$CT_FUN" -a "X$CASE_TYPE" != "X$CT_STRESS" ];then
            echo "$CASE_NAME: configure error to block run the test case"
            exit $CR_CASE
        fi
    else
        echo "$CASE_NAME: configure error to block run the test case"
        exit $CR_CASE
    fi
}

function func_case_get_casename()
{
    local tmp=$(basename $0)
    tmp=${tmp/\.sh/}
    CASE_ID=${tmp/.*/}
    CASE_NAME=${tmp/*./}
    export CASE_NAME CASE_ID
}

function func_case_write_summary_format_title()
{
    func_batf_write_report_title $1
}

function func_case_write_summary_format_result()
{
    cat << END >> $1
$CASE_ID,$CASE_NAME,$CASE_RESULT,$CASE_TYPE,$CASE_RUN_COUNT,$CASE_TIME_TOTAL,$CASE_TIME_AVERAGE
END
}


function func_case_get_reportname()
{
    if [ $CASE_FROM_FRAMEWORK -eq 0 ];then
        CASE_LOG_PATH="$BATF_FD_REPORT/$(date +%Y-%m-%d-%H-%M-%S)/$CASE_NAME"
    else
        CASE_LOG_PATH=$BATF_REPORT_HOME/$CASE_NAME
    fi
    mkdir -p $CASE_LOG_PATH
    echo $CASE_LOG_PATH
    CASE_PROCESS_FILE=$CASE_LOG_PATH/output-log.txt
    CASE_SUMMARY_FILE=$(dirname $CASE_LOG_PATH)/summary.csv
    BATF_SUMMARY_FILE=$CASE_SUMMARY_FILE
    [[ $CASE_FROM_FRAMEWORK -eq 0 ]] && func_case_write_summary_format_title $CASE_SUMMARY_FILE
    export CASE_PROCESS_FILE CASE_SUMMARY_FILE CASE_LOG_PATH
}

function func_case_check_environments()
{
    CASE_START_TIME=$(date +%s)
    if [ $CASE_FROM_FRAMEWORK -eq 0 ];then
        func_batf_check_environments
        if [ $? -ne 0 ];then
            func_batf_debug_call_trace
            exit $CR_ENVCHECK
        fi
    fi

    func_case_dump_description
    func_batf_press_any_key_to "continue"

    # case need update base image by it self
    if [ $CASE_FROM_FRAMEWORK -eq 0 -a "$(type -t $FUNC_CASE_UPGIMAGE)" == "function" ];then
        $FUNC_CASE_UPGIMAGE
        [[ $? -ne 0 ]] && exit $CR_ENVCHECK
    fi
    if [ "$(type -t $FUNC_CASE_ENVCHECK)" == "function" ];then
        $FUNC_CASE_ENVCHECK
        [[ $? -ne 0 ]] && exit $CR_ENVCHECK
    fi
}

function func_case_dump_description()
{
    local tmp_file=$BATF_TMP/description.txt
    cat << END > $tmp_file
$(grep '^##' $CASE_CONF)
Case step:
$(awk  -F '"'  '/^FUNC_CASE_STEP_LST/ {print "\t"$(NF-1)}' "$0")
END
    cat $tmp_file
    [[ "X$CASE_WRITE_LOG" != "X1" ]] && rm -rf $tmp_file && return
    mv  $tmp_file $CASE_LOG_PATH/description.txt
}

function func_case_output()
{
    func_batf_resume_cmd echo
    echo -n $(date +%T)": "
    if [ "X$CASE_WRITE_LOG" == "X1" ];then
        echo $* |tee -a $CASE_PROCESS_FILE
    else
        echo $*
    fi
    func_batf_interrupt_cmd echo
    export -f echo
}

function func_case_send_mail()
{
    # framework will send the result mail, so skip it
    [[ "X$CASE_FROM_FRAMEWORK" == "X1" ]] && return
    # skip option which is not open 
    [[ "X$CASE_SEND_MAIL" != "X1" ]] && return
    # mail_receiver is emplty
    [[ ! "$BATF_EMAIL_RECEIVERS" ]] && return

    local mail_ext_opt=""
    [[ -f "$BATF_HOME/conf/mail_setting.sh" ]] && mail_ext_option="-s $BATF_HOME/conf/mail_setting.sh"

    if [ "$CASE_SUMMARY_FILE" ];then
        func_case_package_result
        send_mail.py -r $CASE_SUMMARY_FILE -a $CASE_LOG_PATH.zip -m "$BATF_EMAIL_RECEIVERS" $mail_ext_option
        [[ $? -ne 0 ]] && echo "Mail send error" && func_batf_debug_call_trace
        rm -rf $CASE_LOG_PATH.zip
    else
        local tmp_file=$BATF_TMP/res.csv
        func_case_write_summary_format_title $tmp_file
        func_case_write_summary_format_result $tmp_file
        [[ $? -ne 0 ]] && echo "Mail send error" && func_batf_debug_call_trace
        rm -rf $tmp_file
    fi
}

function func_case_package_result()
{
    [[ "X$CASE_WRITE_LOG" != "X1" ]] && return
    local cur_path=$PWD
    cd $CASE_LOG_PATH
    info_collect.sh > hardware_info.txt
    unix2dos *.txt
    cd ../
    zip -r $CASE_NAME.zip $CASE_NAME
    cd $cur_path
}

function func_case_run_loop()
{
    local i step
    for(( i=0 ; i < $CASE_RUN_COUNT ; i++ ))
    do
        for step in ${FUNC_CASE_STEP_LST[@]}
        do
            $step
            step_result=$?
            if [ $step_result != 0 ];then
                echo "Loop: ($i/$CASE_RUN_COUNT) step $step failed"
                exit $step_result
            else
                echo "Loop: ($i/$CASE_RUN_COUNT) step $step pass"
            fi
        done
        [ "$(type -t $FUNC_CASE_RESCHECK)" != "function" ] && continue
        $FUNC_CASE_RESCHECK
        [[ $? -ne 0 ]] && exit $CR_ENVCHECK
        echo "Loop: result check after each step pass"
    done
}

function func_case_run_stress()
{
    local step run_time
    local cur_time=$(date +%s)
    local end_time=$[ $cur_time + $CASE_RUN_COUNT * 3600 ]
    local start_time=$cur_time
    while [ $cur_time -lt $end_time ]
    do
        for step in ${FUNC_CASE_STEP_LST[@]}
        do
            $step
            step_result=$?
            cur_time=$(date +%s)
            run_time=$(convert_time.sh $[ $cur_time - $start_time ])
            if [ $step_result != 0 ];then
                echo "Stress: ($run_time/$CASE_RUN_COUNT hour) step $step failed"
                exit $step_result
            else
                echo "Stress: ($run_time/$CASE_RUN_COUNT hour) step $step pass"
            fi
        done
        [ "$(type -t $FUNC_CASE_RESCHECK)" != "function" ] && continue
        $FUNC_CASE_RESCHECK
        [[ $? -ne 0 ]] && exit $CR_ENVCHECK
        echo "Stress: result check after each step pass"
        cur_time=$(date +%s)
    done
    echo "Stress: run finish"
}

function func_case_import_setting()
{
    
    source $BATF_FD_LIB/case_config.sh
    if [ -f $BATF_FD_CONF/$CASE_NAME.sh ];then
        CASE_CONF="$BATF_FD_CONF/$CASE_NAME.sh"
    elif [ -f "$BATF_FD_CONF/$CASE_ID.$CASE_NAME.sh" ];then
        CASE_CONF="$BATF_FD_CONF/$CASE_ID.$CASE_NAME.sh"
    fi
    [[ "$CASE_CONF" ]] && source $CASE_CONF
}

function func_case_interrupt_cmd()
{
    [[ $CASE_FROM_FRAMEWORK -eq 1 ]] && return
    function exit()
    {
        func_case_finish $*
    }
    function echo()
    {
        func_case_output $*
    }
    export -f exit echo
}
