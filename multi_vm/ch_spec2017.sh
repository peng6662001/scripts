#!/bin/bash 
PARAM_NUM=$#

source ../command.sh $@

if [ $# -lt 3 ];then
    showHelp ch
fi

SAVE_DIR=$LOG_DIR/$COPIES/clh
DIR="COPY"`get_string $COPIES`
vm_csv_name=$LOG_DIR/$DIR/clh_`echo $ACTION|sed 's/ /_/g'`/clh.csv
./ch_full.sh $@

sleep 5

one_spec2017_test()
{
    KERNEL=`ssh_command_ip 192.168.$1.2 'uname -r'`

    addr=`get_string $1`
    SAVE_DIR=$LOG_DIR/$DIR/clh_`echo $ACTION|sed 's/ /_/g'`/${KERNEL}"_"$addr
    ssh_command_ip 192.168.$1.2 "cd /home/amptest/ampere_spec2017/ && sudo rm -rf spec2017/result && sudo ./high_perf.sh"
    ssh_command_ip 192.168.$1.2 "sudo echo $THP_CONFIG > /sys/kernel/mm/transparent_hugepage/enabled" 
    if [ $1 -eq 2 ];then
	start_perf
    fi
    ssh_command_ip 192.168.$1.2 "cd /home/amptest/ampere_spec2017/ && sudo ./run_spec2017.sh --iterations $ITER --copies 1 --$BUILD_OPT --action run $ACTION"
    
    if [ $1 -eq 2 ];then
	killall perf
    fi

    scp_pull_ip 192.168.$1.2 "/home/amptest/ampere_spec2017/spec2017/result" $SAVE_DIR/
    record_info clh 
    ssh_command_ip 192.168.$1.2 "sudo shutdown -h now" 
}

let vm_start=$vm_start			
let vm_end=$vm_start+$COPIES
for ((i=$vm_start;i<$vm_end;i++))
do
    one_spec2017_test $i &
done

res=1
while [ $res -ne 0 ]
do
    res=`pgrep cloud-hyperviso|wc -l`
    sleep 10
done
