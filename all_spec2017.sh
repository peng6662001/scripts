#!/bin/bash 

source command.sh $@

if [ $# -lt 3 ];then
    showHelp all 
fi

./host_spec2017.sh $@ &
#./qemu_spec2017.sh $@ &
#./ch_spec2017.sh $@ &

res=1
while [ $res -ne 0 ]
do
    res=0
    let res=$res+`pgrep host_spec|wc -l`
    let res=$res+`pgrep ch_spec|wc -l`
    let res=$res+`pgrep qemu_spec|wc -l`
    sleep 5
done

#killall perf
