#!/bin/bash

source command.sh $@
if [ $# -lt 3 ];then
    showHelp all 
    exit 0
fi

./host_spec2017.sh log_dir $LOG_DIR $@
./qemu_spec2017.sh log_dir $LOG_DIR $@
./ch_spec2017.sh log_dir $LOG_DIR $@
