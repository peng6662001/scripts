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
        ssh_command 3335 ls
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

DIR="COPY"`get_string $COPIES`

create_disk
#python cpu_affinity.py -s /tmp/qmp-test2 {2..41}
python cpu_affinity.py -s /tmp/qmp-test2 {2,3}

start_perf qemu

SAVE_DIR=$LOG_DIR/$DIR/qemu_`echo $ACTION|sed 's/ /_/g'`/`ssh_command 3335 'uname -r'`"_single"

ssh_command 3335 "sudo find /home/amptest/ampere_spec2017/spec2017/benchspec/CPU -maxdepth 2 -iname run -exec rm -rf {} \;"
ssh_command 3335 "sudo echo $THP_CONFIG > /sys/kernel/mm/transparent_hugepage/enabled" 
if [ "$ACTION" == "copies_intrate" ];then
    scp_push 3335 full_test.sh "/home/cloud/"
    ssh_command 3335 "sudo mv /home/cloud/full_test.sh /home/amptest/ampere_spec2017/"
    ssh_command 3335 "sudo chmod a+x /home/amptest/ampere_spec2017/full_test.sh"
    ssh_command 3335 "cd /home/amptest/ampere_spec2017/ && sudo rm -rf spec2017/result && sudo ./high_perf.sh && sudo ./full_test.sh"
else
    ssh_command 3335 "cd /home/amptest/ampere_spec2017/ && sudo rm -rf spec2017/result && sudo ./high_perf.sh && sudo ./run_spec2017.sh --iterations $ITER --copies $COPIES --$BUILD_OPT --action run $ACTION"
fi

scp_pull 3335 "/home/amptest/ampere_spec2017/spec2017/result" $SAVE_DIR
if [ $GROUP -ne 1 ];then
    killall perf
fi

record_info qemu
ssh_command 3335 "sudo shutdown -h now"


reset
