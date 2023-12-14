You can run all_cases.sh to do a full test,or the following commands to do a special test.

all_spec2017_test.sh calls host_spec2017.sh,qemu_spec2017.sh and ch_spec2017.sh
all_spec2017_test.sh 1 4 500.perlbench_r 520.omnetpp_r
all_spec2017_test.sh 1 4 intrate

1 means iterations
4 means copies

./qemu_spec2017.sh 1 4 500.perlbench_r 520.omnetpp_r
./ch_spec2017.sh 1 4 500.perlbench_r 520.omnetpp_r

./qemu_spec2017.sh 1 1 520.omnetpp_r

Logs are in workloads
eg:
workloads/qemu_520.omnetpp_r_20231023_190542_base.csv
workloads/qemu_520.omnetpp_r_20231023_190542_base_parse.csv
workloads/qemu_520.omnetpp_r_20231023_190542_vm_base.csv
workloads/qemu_520.omnetpp_r_20231023_190542_vm_base_parse.csv




result_altra_ch_6.3.0-rc4_org_i3_copies_1030
result_altra_			ch_					6.3.0-rc4_org_		i3_					copies_				1030   
	   altra server		cloud-hypervisor 	kernel on vm		iteration 3			multi copies		tested date


python parse_spec2017 servers
check full_data.csv

Logs directory:
servers/
└── log_505.mcf_r_20231108_232550
    ├── clh.csv
    ├── host.csv
    ├── one_6.6.0-rc6
    │   ├── CPU2017.001.intrate.refrate.csv
    ├── one_clh_6.6.0-rc6
    │   ├── CPU2017.001.intrate.refrate.csv
    ├── one_qemu_6.6.0-rc6
    │   ├── CPU2017.001.intrate.refrate.csv
    └── qemu.csv
