#!/bin/bash
PARAM_NUM=$#

source command.sh $@

if [ $# -lt 3 ];then
    showHelp ch
fi


SAVE_DIR=$LOG_DIR/$COPIES/clh
DIR="COPY"`get_string $COPIES`
vm_csv_name=$LOG_DIR/$DIR/clh_`echo $ACTION|sed 's/ /_/g'`/clh.csv

./ch_full.sh

SAVE_DIR=$LOG_DIR/$DIR/clh_`echo $ACTION|sed 's/ /_/g'`/`ssh_command_ip 192.168.2.2 'uname -r'`"_single"

ssh_command_ip 192.168.2.2 "sudo rm -rf /home/amptest/ampere_spec2017/spec2017/result"
ssh_command_ip 192.168.2.2 "sudo echo $THP_CONFIG > /sys/kernel/mm/transparent_hugepage/enabled" 
if [ "$ACTION" == "copies_intrate" ];then
    scp_push_ch full_test.sh "/home/cloud/"
    ssh_command_ip 192.168.2.2 "sudo mv /home/cloud/full_test.sh /home/amptest/ampere_spec2017/"
    ssh_command_ip 192.168.2.2 "sudo chmod a+x /home/amptest/ampere_spec2017/full_test.sh"
    ssh_command_ip 192.168.2.2 "cd /home/amptest/ampere_spec2017/ && sudo rm -rf spec2017/result && sudo ./high_perf.sh && sudo ./full_test.sh"
else
    ssh_command_ip 192.168.2.2 "cd /home/amptest/ampere_spec2017/ && sudo rm -rf spec2017/result && sudo ./high_perf.sh"
    start_perf
    ssh_command_ip 192.168.2.2 "cd /home/amptest/ampere_spec2017/ && sudo ./run_spec2017.sh --iterations $ITER --copies $COPIES --$BUILD_OPT --action run $ACTION"
fi

scp_pull_ip 192.168.$1.2 "/home/amptest/ampere_spec2017/spec2017/result" $SAVE_DIR

if [ $GROUP -ne 1 ];then
    killall perf
fi
ssh_command_ip 192.168.2.2 "sudo shutdown -h now" 
reset
