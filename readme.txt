You can run all_cases.sh to do a full test,it runs tests on host,one qemu and one clh instance at the same time.

all_spec2017.sh calls host_spec2017.sh,qemu_spec2017.sh and ch_spec2017.sh,it need some parameters,eg:

all_spec2017.sh 1 4 500.perlbench_r 520.omnetpp_r
all_spec2017.sh 1 4 intrate

1 means iterations
4 means copies

If you only want to test with qemu,use ./qemu_spec2017.sh 1 4 500.perlbench_r 520.omnetpp_r
intrate include all the cases of 500.perlbench_r,502.gcc_r,505.mcf_r,520.omnetpp_r,523.xalancbmk_r,525.x264_r,531.deepsjeng_r,541.leela_r,548.exchange2_r,557.xz_r

Logs are in workloads
eg:
workloads/log_20240219_073349/COPY16/clh_500.perlbench_r/6.6.0-rc6/CPU2017.001.intrate.refrate.txt
It runs 16 copies at the same time, testing 500.perlbench_r on clh with kernel 6.6.0.

After get the logs,we can run `python parse_spec2017.py workloads/log_20240219_073349` to parse the logs and perf data.
It generates csv results in workloads/log_20240219_073349. 
