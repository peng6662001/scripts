all_spec2017_test.sh calls host_spec2017.sh,qemu_spec2017.sh and ch_spec2017.sh
all_spec2017_test.sh 1 4 500.perlbench_r 520.omnetpp_r
all_spec2017_test.sh 1 4 intrate



./qemu_spec2017.sh 1 4 500.perlbench_r 520.omnetpp_r
./ch_spec2017.sh 1 4 500.perlbench_r 520.omnetpp_r

./qemu_spec2017.sh 1 1 520.omnetpp_r

Logs are in workloads
eg:
workloads/qemu_520.omnetpp_r_20231023_190542_base.csv
workloads/qemu_520.omnetpp_r_20231023_190542_base_parse.csv
workloads/qemu_520.omnetpp_r_20231023_190542_vm_base.csv
workloads/qemu_520.omnetpp_r_20231023_190542_vm_base_parse.csv
