#!/bin/bash

#500.perlbench_r 502.gcc_r 505.mcf_r 520.omnetpp_r 523.xalancbmk_r 525.x264_r 531.deepsjeng_r 541.leela_r 548.exchange2_r 557.xz_r

test_copies()
{
    COPYS=1
    
    while ((COPYS<=32))
    do
        sudo ./all_spec2017.sh 1 $COPYS "$1"
	#echo all_spec2017.sh 1 $COPYS "$1"
        ((COPYS *= 2))
    done
}

array_spec=(500.perlbench_r 502.gcc_r 505.mcf_r 520.omnetpp_r 523.xalancbmk_r 525.x264_r 531.deepsjeng_r 541.leela_r 548.exchange2_r 557.xz_r)

for name in "${array_spec[@]}"
do
    test_copies $name
done





