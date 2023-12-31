#!/bin/bash 

if [ $# -lt 1 ];then
    echo "usage:./pmu_mem_bw.sh 1"
    exit 1
fi

duration=$1

wr_cmd="ampere_mcu_pmu_0/wr_wra_sent/"
rd_cmd="ampere_mcu_pmu_0/rd_rda_sent/"

COUNT=31
temp=`numactl -H | grep "available: 1 nodes"`
if [ "$temp" != "" ];then
    COUNT=15
fi

for i in $(seq 1 $COUNT)
do
	wr_cmd="$wr_cmd,ampere_mcu_pmu_$i/wr_wra_sent/"
	rd_cmd="$rd_cmd,ampere_mcu_pmu_$i/rd_rda_sent/"
done

while [ 1 ]
do
	perf stat -I 1000 -e $wr_cmd,$rd_cmd -o mem_bw.log -x, -- sleep $duration
	python ./mem_bw.py mem_bw.log $duration $COUNT
	sleep 1
done

