#!/bin/bash -x
PARAM_NUM=$#

source command.sh $@

if [ $PARAM_NUM -lt 3 ];then
    showHelp qemu
    exit 0
fi
result_dir=${cpu_name}"_"`uname -r`

host_test()
{
    csv_name=$LOG_DIR/host.csv
    if [ "$ACTION" == "copies_intrate" ];then
        cp full_test.sh /home/amptest/ampere_spec2017/
    fi

    pushd /home/amptest/ampere_spec2017/
    rm -rf spec2017/result
    rm -rf spec2017/$result_dir
    ./high_perf.sh

    if [ $cpu_name == "one" ];then
        perf stat -C 1 -e cycles,instructions,stall_backend,stall_frontend,STALL_BACKEND_TLB,STALL_BACKEND_CACHE,STALL_BACKEND_MEM,mem_access,l1d_tlb,l1d_tlb_refill,l2d_tlb,l2d_tlb_refill,dtlb_walk,rd80d,stall_slot_backend,op_spec,op_retired,STALL_BACKEND_RESOURCE -I 1000 -x , -o $csv_name &
    fi

    if [ $cpu_name == "altra" ];then
        perf stat -C 1 -e cycles,instructions,stall_backend,stall_frontend,mem_access,l2d_tlb,l2d_tlb_refill,dtlb_walk,inst_spec,inst_retired -I 1000 -x , -o $csv_name &
    fi

    if [ "$ACTION" == "copies_intrate" ];then
	sudo chmod a+x full_test.sh
        ./full_test.sh
    else
        ./run_spec2017.sh --iterations $ITER --copies $COPIES --nobuild --action run $ACTION
    fi
    killall perf
    sudo mv /home/amptest/ampere_spec2017/spec2017/result /home/amptest/ampere_spec2017/spec2017/$result_dir
    cp -r "/home/amptest/ampere_spec2017/spec2017/$result_dir" $LOG_DIR
    popd
    #python3 ./process_csv.py $csv_name
}

host_test
