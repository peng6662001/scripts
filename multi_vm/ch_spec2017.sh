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
ps aux | grep cloud-hypervisor | wc -l

sleep 5

if [ $cpu_name == "one" ];then
    perf stat -C 81 -e cycles:G,cycles:H,instructions:G,stall_backend:G,stall_frontend:G,STALL_BACKEND_TLB:G,STALL_BACKEND_CACHE:G,STALL_BACKEND_MEM:G,mem_access:G,l1d_tlb:G,l1d_tlb_refill:G,l2d_tlb:G,l2d_tlb_refill:G,dtlb_walk:G,rd80d:G,stall_slot_backend:G,op_spec:G,op_retired:G,STALL_BACKEND_RESOURCE:G -I 1000 -x , -o $vm_csv_name &
fi
if [ $cpu_name == "altra" ];then
    perf stat -C 81 -e cycles:G,cycles:H,instructions:G,stall_backend:G,stall_frontend:G,mem_access:G,l2d_tlb:G,l2d_tlb_refill:G,dtlb_walk:G,inst_spec:G,inst_retired:G -I 1000 -x , -o $vm_csv_name &
fi

KERNEL=`ssh_command_ip 192.168.2.2 'uname -r'`
result_dir="/home/cloud/log_"${cpu_name}"_"$KERNEL

one_spec2017_test()
{
    addr=`get_string $1`
    SAVE_DIR=$LOG_DIR/$DIR/clh_`echo $ACTION|sed 's/ /_/g'`/${KERNEL}"_clh_"$addr
    if [ $BUILD_OPT == "rebuild" ];then
	ssh_command_ip 192.168.$1.2 "sudo rm -rf ${result_dir}_$addr"
    fi
    ssh_command_ip 192.168.$1.2 "sudo rm -rf ${result_dir}_$addr/result"
    ssh_command_ip 192.168.$1.2 "cd /home/amptest/ampere_spec2017/ && sudo ./high_perf.sh && sudo ./run_spec2017_vm.sh --config=ampere_aarch64_vm --output_root ${result_dir}_$addr --iterations $ITER --copies 1 --$BUILD_OPT --action run $ACTION"
    if [ $GROUP -ne 1 ];then
       killall perf
    fi

    scp_pull_ip 192.168.$1.2 "${result_dir}_$addr/result/" $SAVE_DIR/
    ssh_command_ip 192.168.$1.2 "sudo shutdown -h now" 
}

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

killall cloud-hypervisor
reset
