#!/bin/bash -x
PARAM_NUM=$#

source command.sh $@

if [ $# -lt 3 ];then
    showHelp ch
fi

if [ ! -f $WORKLOADS_DIR/Fedora-Cloud-Base-38-1.6.aarch64.raw ];then
   ./qemu_spec2017.sh create_disk
   killall qemu-system-aarch64
fi

vm_csv_name=$LOG_DIR/clh.csv
./ch_full.sh

if [ $cpu_name == "one" ];then
    perf stat -C 2 -e cycles:G,cycles:H,instructions:G,stall_backend:G,stall_frontend:G,STALL_BACKEND_TLB:G,STALL_BACKEND_CACHE:G,STALL_BACKEND_MEM:G,mem_access:G,l1d_tlb:G,l1d_tlb_refill:G,l2d_tlb:G,l2d_tlb_refill:G,dtlb_walk:G,rd80d:G,stall_slot_backend:G,op_spec:G,op_retired:G,STALL_BACKEND_RESOURCE:G -I 1000 -x , -o $vm_csv_name &
fi
if [ $cpu_name == "altra" ];then
    perf stat -C 2 -e cycles:G,cycles:H,instructions:G,stall_backend:G,stall_frontend:G,mem_access:G,l2d_tlb:G,l2d_tlb_refill:G,dtlb_walk:G,inst_spec:G,inst_retired:G -I 1000 -x , -o $vm_csv_name &
fi

result_dir=${cpu_name}"_clh_"`ssh_command_ch 'uname -r'`
if [ "$ACTION" == "copies_intrate" ];then
    scp_push_ch full_test.sh "/home/cloud/"
    ssh_command_ch "sudo mv /home/cloud/full_test.sh /home/amptest/ampere_spec2017/"
    ssh_command_ch "sudo chmod a+x /home/amptest/ampere_spec2017/full_test.sh"
    ssh_command_ch "cd /home/amptest/ampere_spec2017/ && sudo rm -rf spec2017/result && sudo rm -rf spec2017/$result_dir && sudo ./high_perf.sh && sudo ./full_test.sh"
else
    ssh_command_ch "cd /home/amptest/ampere_spec2017/ && sudo rm -rf spec2017/result && sudo rm -rf spec2017/$result_dir && sudo ./high_perf.sh && sudo ./run_spec2017.sh --iterations $ITER --copies $COPIES --nobuild --action run $ACTION"
fi

ssh_command_ch "sudo mv /home/amptest/ampere_spec2017/spec2017/result /home/amptest/ampere_spec2017/spec2017/$result_dir"
scp_pull_ch "/home/amptest/ampere_spec2017/spec2017/$result_dir" $LOG_DIR
killall perf
killall cloud-hypervisor

reset
