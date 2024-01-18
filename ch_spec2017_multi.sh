#!/bin/bash -x
PARAM_NUM=$#

source command.sh $@

if [ $# -lt 3 ];then
    showHelp ch
fi

vm_csv_name=$LOG_DIR/clh.csv
./ch_full_multi.sh

sleep 5

if [ $cpu_name == "one" ];then
    perf stat -C 2 -e cycles:G,cycles:H,instructions:G,stall_backend:G,stall_frontend:G,STALL_BACKEND_TLB:G,STALL_BACKEND_CACHE:G,STALL_BACKEND_MEM:G,mem_access:G,l1d_tlb:G,l1d_tlb_refill:G,l2d_tlb:G,l2d_tlb_refill:G,dtlb_walk:G,rd80d:G,stall_slot_backend:G,op_spec:G,op_retired:G,STALL_BACKEND_RESOURCE:G -I 1000 -x , -o $vm_csv_name &
fi
if [ $cpu_name == "altra" ];then
    perf stat -C 2 -e cycles:G,cycles:H,instructions:G,stall_backend:G,stall_frontend:G,mem_access:G,l2d_tlb:G,l2d_tlb_refill:G,dtlb_walk:G,inst_spec:G,inst_retired:G -I 1000 -x , -o $vm_csv_name &
fi

VMS=4
result_dir=${cpu_name}"_clh_"`ssh_command_chs 2 1 'uname -r'`
COMPLETE=0

one_spec2017_test()
{
    ssh_command_ip 192.168.$1.2 "cd /home/amptest/ampere_spec2017/ && sudo rm -rf spec2017/result && sudo rm -rf spec2017/${result_dir}* && sudo ./high_perf.sh && sudo ./run_spec2017_vm.sh --config=ampere_aarch64_vm_$1 --iterations $ITER --copies $COPIES --nobuild --action run $ACTION"
    ssh_command_ip 192.168.$1.2 "sudo mv /home/amptest/ampere_spec2017/spec2017/result /home/amptest/ampere_spec2017/spec2017/${result_dir}_$1"
    scp_pull_ip 192.168.$1.2 "/home/amptest/ampere_spec2017/spec2017/${result_dir}_$1" $LOG_DIR
    ssh_command_ip 192.168.$1.2 "sudo shutdown -h now" 
    let COMPLETE=$COMPLETE+1
}

for ((i=2;i<($VMS+2);i++))
do
    one_spec2017_test $i &
done

while [ $COMPLETE -lt $VMS ]
do
    ssh_command_chs 2 $VMS ls
    if [ $? -eq 0 ];then
	break
    fi
    sleep 5
done

killall perf
killall cloud-hypervisor

reset
