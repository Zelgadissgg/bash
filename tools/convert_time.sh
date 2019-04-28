#!/bin/bash

[[ ! "$1" ]] && exit

ret='' time=$1
[[ "X$[ $time / 86400 ]" != "X0" ]] && ret=$[ $time / 86400 ]" day "
time=$[ $time % 86400 ]
[[ "X$[ $time / 3600 ]" != "X0" ]] && ret=$ret$[ $time / 3600 ]" hr "
time=$[ $time % 3600 ]
[[ "X$[ $time / 60 ]" != "X0" ]] && ret=$ret$[ $time / 60 ]" min "
time=$[ $time % 60 ]
ret=$ret$time" sec"
cat << END
$ret
END
