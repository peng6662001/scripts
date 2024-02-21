#!/bin/bash

#500.perlbench_r 502.gcc_r 505.mcf_r 520.omnetpp_r 523.xalancbmk_r 525.x264_r 531.deepsjeng_r 541.leela_r 548.exchange2_r 557.xz_r

source ../command.sh
if [ "$BUILD_OPT" == "rebuild" ];then
    echo "only rebuild"
    let vm_end=$vm_start+$COPIES
    for ((i=$vm_start;i<$vm_end;i++))
    do
        prepare_disks $i
    done
     
    ./ch_spec2017.sh log_dir /home/dom/scripts/workloads/log_rebuild 1 32 intrate
    exit 0
fi

test_copies()
{
    COPYS=1
    while ((COPYS<=1))
    do
	DIR="COPY"`get_string $COPYS` 
	echo all_spec2017.sh 1 $COPYS "$1"
	mkdir -p $LOG_DIR/$DIR/host_`echo $1|sed 's/ /_/g'`
	mkdir -p $LOG_DIR/$DIR/clh_`echo $1|sed 's/ /_/g'`
	mkdir -p $LOG_DIR/$DIR/qemu_`echo $1|sed 's/ /_/g'`
        ./all_spec2017.sh log_dir $LOG_DIR 1 $COPYS "$1"
        ((COPYS *= 2))
    done
}

#array_spec=(500.perlbench_r 502.gcc_r 505.mcf_r 520.omnetpp_r 523.xalancbmk_r 525.x264_r 531.deepsjeng_r 541.leela_r 548.exchange2_r 557.xz_r)
array_spec=(502.gcc_r)

for name in "${array_spec[@]}"
do
    test_copies $name
done





