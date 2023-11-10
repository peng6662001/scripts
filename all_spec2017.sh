#!/bin/bash

source command.sh $@
showHelp all 

./host_spec2017.sh log_dir $LOG_DIR $@ #2>&1 > $LOG_DIR/run.log
./qemu_spec2017.sh log_dir $LOG_DIR $@ #2>&1 >> $LOG_DIR/run.log
./ch_spec2017.sh log_dir $LOG_DIR $@ #2>&1 >> $LOG_DIR/run.log
