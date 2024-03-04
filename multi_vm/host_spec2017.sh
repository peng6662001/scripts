#!/bin/bash -x
PARAM_NUM=$#

source ../command.sh $@

if [ $# -lt 3 ];then
    showHelp host
fi
result_dir=${cpu_name}"_"`uname -r`

host_test()
{
    addr=`get_string $1`
    DIR="COPY"`get_string $COPIES`
    SAVE_DIR=$LOG_DIR/$DIR/host_`echo $ACTION|sed 's/ /_/g'`/`uname -r`
    csv_name=$LOG_DIR/$DIR/host_`echo $ACTION|sed 's/ /_/g'`/host.csv
    if [ "$ACTION" == "copies_intrate" ];then
        cp full_test.sh /home/amptest/ampere_spec2017/
    fi

    pushd /home/amptest/ampere_spec2017/
    sed -i 's/physcpubind=$SPECCOPYNUM/physcpubind=`expr $SPECCOPYNUM + 1`/' /home/amptest/ampere_spec2017/spec2017/config/ampere_aarch64.cfg
    find /home/amptest/ampere_spec2017/spec2017/benchspec/CPU -maxdepth 2 -iname run -exec rm -rf {} \;
    rm -rf spec2017/result
    rm -rf spec2017/$result_dir
    ./high_perf.sh

    if [ $cpu_name == "one" ];then
        perf stat -C 1 -e cycles,instructions,stall_backend,stall_frontend,STALL_BACKEND_TLB,STALL_BACKEND_CACHE,STALL_BACKEND_MEM,mem_access,l1d_tlb,l1d_tlb_refill,l2d_tlb,l2d_tlb_refill,dtlb_walk,rd80d,stall_slot_backend,op_spec,op_retired,STALL_BACKEND_RESOURCE -I 1000 -x , -o $csv_name &
    fi

    if [ $cpu_name == "altra" ];then
        perf stat -C 1 -e cycles,instructions,stall_backend,stall_frontend,mem_access,l2d_tlb,l2d_tlb_refill,dtlb_walk,inst_spec,inst_retired -I 1000 -x , -o $csv_name &
    fi
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
    rm -rf "/home/amptest/ampere_spec2017/spec2017/result"
    if [ "$ACTION" == "copies_intrate" ];then
	sudo chmod a+x full_test.sh
        ./full_test.sh
    else
        ./run_spec2017.sh --iterations $ITER --copies $COPIES --$BUILD_OPT --action run $ACTION
    fi
    if [ $GROUP -ne 1 ];then
	killall perf
    fi
    sudo mv /home/amptest/ampere_spec2017/spec2017/result $SAVE_DIR
    popd
    #python3 ./process_csv.py $csv_name
}

host_test
