#!/bin/bash -x
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

vm_csv_name=$LOG_DIR/qemu.csv

#create_disk
python cpu_affinity.py -s /tmp/qmp-test2 {1..40}

if [ $cpu_name == "one" ];then
    perf stat -C 2 -e cycles:G,cycles:H,instructions:G,stall_backend:G,stall_frontend:G,STALL_BACKEND_TLB:G,STALL_BACKEND_CACHE:G,STALL_BACKEND_MEM:G,mem_access:G,l1d_tlb:G,l1d_tlb_refill:G,l2d_tlb:G,l2d_tlb_refill:G,dtlb_walk:G,rd80d:G,stall_slot_backend:G,op_spec:G,op_retired:G,STALL_BACKEND_RESOURCE:G -I 1000 -x , -o $vm_csv_name &
fi
if [ $cpu_name == "altra" ];then
    perf stat -C 2 -e cycles:G,cycles:H,instructions:G,stall_backend:G,stall_frontend:G,mem_access:G,l2d_tlb:G,l2d_tlb_refill:G,dtlb_walk:G,inst_spec:G,inst_retired:G -I 1000 -x , -o $vm_csv_name &
fi

#ssh_command "sudo find /home/amptest/ampere_spec2017/spec2017/benchspec/CPU -maxdepth 2 -iname run -exec rm -rf {} \;"

DIR="COPY"`get_string $COPIES`
vm_csv_name=$LOG_DIR/$DIR/qemu_`echo $ACTION|sed 's/ /_/g'`/qemu.csv
KERNEL=`ssh_command 3335 'uname -r'`
result_dir="/home/cloud/log_"${cpu_name}"_"$KERNEL

one_spec2017_test()
{
    addr=`get_string $1`
    let port=3333+$1
    SAVE_DIR=$LOG_DIR/$DIR/qemu_`echo $ACTION|sed 's/ /_/g'`/${KERNEL}"_qemu_"$addr
    python ../cpu_affinity.py -s /tmp/qmp-test$addr $1

    if [ "$ACTION" == "copies_intrate" ];then
        scp_push full_test.sh "/home/cloud/"
        ssh_command "sudo mv /home/cloud/full_test.sh /home/amptest/ampere_spec2017/"
        ssh_command "sudo chmod a+x /home/amptest/ampere_spec2017/full_test.sh"
        ssh_command "cd /home/amptest/ampere_spec2017/ && sudo rm -rf spec2017/result && sudo rm -rf spec2017/$result_dir && sudo ./high_perf.sh && sudo ./full_test.sh"
    else
        ssh_command $port "export GLIBC_TUNABLES=glibc.malloc.hugetlb=2 && sudo rm -rf ${result_dir}_$addr/result && cd /home/amptest/ampere_spec2017/ && sudo ./high_perf.sh && sudo ./run_spec2017.sh --config=ampere_aarch64_vm --output_root ${result_dir}_$addr --iterations $ITER --copies $COPIES --$BUILD_OPT --action run $ACTION"
    fi
    scp_pull $port "${result_dir}_$addr/result/" $SAVE_DIR/
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
    res=`pgrep qemu-system-aarch64|wc -l`
    sleep 10
done

killall perf
reset
