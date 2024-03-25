#!/bin/bash
PARAM_NUM=$#

source command.sh $@

if [ $# -lt 3 ];then
    showHelp host
fi
result_dir=${cpu_name}"_"`uname -r`

host_test()
{
    DIR="COPY"`get_string $COPIES`
    SAVE_DIR=$LOG_DIR/$DIR/host_`echo $ACTION|sed 's/ /_/g'`/`uname -r`
    if [ "$ACTION" == "copies_intrate" ];then
        cp full_test.sh /home/amptest/ampere_spec2017/
    fi

    pushd /home/amptest/ampere_spec2017/
    sed -i 's/physcpubind=$SPECCOPYNUM/physcpubind=`expr $SPECCOPYNUM + 2`/' /home/amptest/ampere_spec2017/spec2017/config/ampere_aarch64.cfg
    #find /home/amptest/ampere_spec2017/spec2017/benchspec/CPU -maxdepth 2 -iname run -exec rm -rf {} \;
    rm -rf spec2017/result
    rm -rf spec2017/$result_dir
    sudo ./high_perf.sh

    start_perf host
    sudo echo $THP_CONFIG > /sys/kernel/mm/transparent_hugepage/enabled
    rm -rf "/home/amptest/ampere_spec2017/spec2017/result"
    if [ "$ACTION" == "copies_intrate" ];then
	sudo chmod a+x full_test.sh
        ./full_test.sh
    else
        ./run_spec2017.sh --iterations $ITER --copies $COPIES --$BUILD_OPT --action run $ACTION
    fi

    killall perf
    record_info host
    sudo mv /home/amptest/ampere_spec2017/spec2017/result $SAVE_DIR
    popd
}

host_test
