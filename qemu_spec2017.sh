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

vm_csv_name=$LOG_DIR/qemu.csv

create_disk
python cpu_affinity.py -s /tmp/qmp-test2 {41..80}

if [ $cpu_name == "one" ];then
    perf stat -C 41 -e cycles:G,cycles:H,instructions:G,stall_backend:G,stall_frontend:G,STALL_BACKEND_TLB:G,STALL_BACKEND_CACHE:G,STALL_BACKEND_MEM:G,mem_access:G,l1d_tlb:G,l1d_tlb_refill:G,l2d_tlb:G,l2d_tlb_refill:G,dtlb_walk:G,rd80d:G,stall_slot_backend:G,op_spec:G,op_retired:G,STALL_BACKEND_RESOURCE:G -I 1000 -x , -o $vm_csv_name &
fi
if [ $cpu_name == "altra" ];then
    perf stat -C 41 -e cycles:G,cycles:H,instructions:G,stall_backend:G,stall_frontend:G,mem_access:G,l2d_tlb:G,l2d_tlb_refill:G,dtlb_walk:G,inst_spec:G,inst_retired:G -I 1000 -x , -o $vm_csv_name &
fi

ssh_command "sudo find /home/amptest/ampere_spec2017/spec2017/benchspec/CPU -maxdepth 2 -iname run -exec rm -rf {} \;"

result_dir=${cpu_name}"_qemu_"`ssh_command 'uname -r'`
if [ "$ACTION" == "copies_intrate" ];then
    scp_push full_test.sh "/home/cloud/"
    ssh_command "sudo mv /home/cloud/full_test.sh /home/amptest/ampere_spec2017/"
    ssh_command "sudo chmod a+x /home/amptest/ampere_spec2017/full_test.sh"
    ssh_command "cd /home/amptest/ampere_spec2017/ && sudo rm -rf spec2017/result && sudo rm -rf spec2017/$result_dir && sudo ./high_perf.sh && sudo ./full_test.sh"
else
    ssh_command "export GLIBC_TUNABLES=glibc.malloc.hugetlb=2 && cd /home/amptest/ampere_spec2017/ && sudo rm -rf spec2017/result && sudo rm -rf spec2017/$result_dir && sudo ./high_perf.sh && sudo ./run_spec2017.sh --iterations $ITER --copies $COPIES --nobuild --action run $ACTION"
fi
ssh_command "sudo mv /home/amptest/ampere_spec2017/spec2017/result /home/amptest/ampere_spec2017/spec2017/$result_dir"
scp_pull "/home/amptest/ampere_spec2017/spec2017/$result_dir" $LOG_DIR
if [ $GROUP -ne 1 ];then
    killall perf
fi
killall qemu-system-aarch64
#python3 process_csv.py $vm_csv_name

reset
