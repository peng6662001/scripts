#!/bin/bash
PARAM_NUM=$#

source command.sh $@

if [ $# -lt 3 ];then
    showHelp qemu
fi

create_disk()
{
    killall qemu-system-aarch64
    ./qemu_full.sh

    sleep 5

    res=1
    while [ $res -ne 0 ];
    do
        ssh_command ls
        res=$?
        sleep 1
    done
    
    sleep 5
    export GLIBC_TUNABLES=glibc.malloc.hugetlb=0
    prepare_spec2017
}

if [ $1 == "create_disk" ];then
    create_disk	
    killall qemu-system-aarch64
    reset
    exit 0
fi

source qemu_full.sh $@
run_all_vms
wait_all_vms_onine

DIR="COPY"`get_string $COPIES`
vm_csv_name=$LOG_DIR/$DIR/qemu_`echo $ACTION|sed 's/ /_/g'`/qemu.csv

one_spec2017_test()
{
    addr=`get_string $1`
    let port=3333+$1
    let pcpu=$1*2
    let pcpu2=$pcpu+1
    
    KERNEL=`ssh_command $port 'uname -r'`

    SAVE_DIR=$LOG_DIR/$DIR/qemu_`echo $ACTION|sed 's/ /_/g'`/${KERNEL}"_"$addr
    python ../cpu_affinity.py -s /tmp/qmp-test$addr $pcpu,$pcpu2

    if [ "$ACTION" == "copies_intrate" ];then
        scp_push full_test.sh "/home/cloud/"
        ssh_command "sudo mv /home/cloud/full_test.sh /home/amptest/ampere_spec2017/"
        ssh_command "sudo chmod a+x /home/amptest/ampere_spec2017/full_test.sh"
        ssh_command "cd /home/amptest/ampere_spec2017/ && sudo rm -rf spec2017/result && sudo ./high_perf.sh && sudo ./full_test.sh"
    else
        ssh_command $port "cd /home/amptest/ampere_spec2017/ && sudo rm -rf spec2017/result && sudo ./high_perf.sh"
        ssh_command $port "sudo echo $THP_CONFIG > /sys/kernel/mm/transparent_hugepage/enabled" 
	if [ $1 -eq 2 ];then
	    start_perf
	fi
        ssh_command $port "cd /home/amptest/ampere_spec2017/ && sudo ./run_spec2017.sh --iterations $ITER --copies 1 --$BUILD_OPT --action run $ACTION"
    fi
    if [ $1 -eq 2 ];then
        killall perf
    fi
    scp_pull $port "/home/amptest/ampere_spec2017/spec2017/result" $SAVE_DIR/

    record_info qemu
    ssh_command $port "sudo shutdown -h now"
}

let vm_end=$vm_start+$COPIES
for ((i=$vm_start;i<$vm_end;i++))
do
    one_spec2017_test $i &
done

res=1
while [ $res -ne 0 ]
do
    res=`pgrep qemu-system|wc -l`
    sleep 10
done
echo "test complete"

killall qemu-system-aarch64
reset
