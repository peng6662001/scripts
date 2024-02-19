#!/bin/bash 

source command.sh $@

if [ $# -lt 3 ];then
    showHelp all 
fi

./host_spec2017.sh $@ & #2>&1 > $LOG_DIR/run.log
./qemu_spec2017.sh $@ & #2>&1 >> $LOG_DIR/run.log
./ch_spec2017.sh $@ &  #2>&1 >> $LOG_DIR/run.log

res=1
while [ $res -ne 0 ]
do
    res=0
    let res=$res+`pgrep host_spec|wc -l`
    let res=$res+`pgrep ch_spec|wc -l`
    let res=$res+`pgrep qemu_spec|wc -l`
    sleep 5
done

killall perf
