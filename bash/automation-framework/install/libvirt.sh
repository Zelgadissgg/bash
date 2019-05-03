#!/bin/bash

case "$OS_NAME" in
"ubuntu")
    apt-get install libvirt0 vir-manager
    ;;
*)
    echo "Unconfigure $OS_NAME/$OS_VERSION for this plugin"
    ;;
esac
