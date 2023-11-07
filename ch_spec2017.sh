#!/bin/bash -x
PARAM_NUM=$#

source command.sh $@

if [ $PARAM_NUM -lt 3 ];then
    showHelp ch
    exit 0
fi

if [ ! -f $WORKLOADS_DIR/Fedora-Cloud-Base-38-1.6.aarch64.raw ];then
   ./qemu_spec2017.sh create_disk
   killall qemu-system-aarch64
fi

vm_csv_name=$LOG_DIR/clh.csv
./ch_full.sh


perf stat -C 2 -e cycles:G,cycles:H,instructions:G,stall_backend:G,stall_frontend:G,STALL_BACKEND_TLB:G,STALL_BACKEND_CACHE:G,STALL_BACKEND_MEM:G,mem_access:G,l1d_tlb:G,l1d_tlb_refill:G,l2d_tlb:G,l2d_tlb_refill:G,dtlb_walk:G,rd80d:G,stall_slot_backend:G,op_spec:G,op_retired:G,STALL_BACKEND_RESOURCE:G -I 1000 -x , -o $vm_csv_name &
ssh_command_ch "cd /home/amptest/ampere_spec2017/ && sudo rm -r spec2017/result && sudo ./high_perf.sh  && sudo ./run_spec2017.sh --iterations $ITER --copies $COPIES --nobuild --action run $ACTION"

result_dir=${cpu_name}"_clh_"`ssh_command 'uname -r'`
ssh_command_ch "sudo mv /home/amptest/ampere_spec2017/spec2017/result /home/amptest/ampere_spec2017/spec2017/$result_dir"
scp_command_ch "/home/amptest/ampere_spec2017/spec2017/$result_dir" $LOG_DIR
killall perf
killall cloud-hypervisor

reset
