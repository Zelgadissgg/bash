#!/bin/bash

CMD="git log"
CMD_OPTION="--pretty=oneline --abbrev-commit"
if [ "$1" ];then
    if [ -f "$1" ];then
    CMD_OPTION=$CMD_OPTION" $1"
    elif [ "$2" ];then
    CMD_OPTION=$CMD_OPTION" $1..$2"
    elif [ "$3" ];then
    CMD_OPTION=$CMD_OPTION" $1 $2..$3"
    else
    CMD_OPTION=$CMD_OPTION" $1..HEAD"
    fi
fi

$CMD $CMD_OPTION
