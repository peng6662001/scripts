#!/bin/bash -x 
ADDR=127.0.0.1
PORT=3333
USER=cloud
PASS=cloud123
cpu_name="one"
vm_count=32
vm_start=2
COPIES=32
GROUP=0
THP_CONFIG="never"
let vm_end=$vm_start+$vm_count
MULTI_VM=${PWD:0-8:8}
BUILD_OPT=nobuild		#it's better to rebuild once to generate necessary files to reduce the total test time,then modify it to nobuild

if [ $MULTI_VM == "multi_vm" ];then
    WORKLOADS_DIR=$PWD/../workloads
else
    WORKLOADS_DIR=$PWD/workloads
fi
LOG_DIR=$WORKLOADS_DIR/latest
DISKS_DIR=$WORKLOADS_DIR/disks

if [ ! -e $WORKLOADS_DIR ];then
  mkdir $WORKLOADS_DIR
fi

if [ ! -e $DISKS_DIR ];then
  mkdir $DISKS_DIR
fi

showHelp()
{
    device=$1
    echo -e "\nusage:"
    echo "sudo ./${device}_spec2017.sh 1 4 500.perlbench_r 502.gcc_r 505.mcf_r 520.omnetpp_r 523.xalancbmk_r 525.x264_r 531.deepsjeng_r 541.leela_r 548.exchange2_r 557.xz_r"
    echo "sudo ./${device}_spec2017.sh 1 4 intrate"
    echo "sudo ./${device}_spec2017.sh 1 4 copies_intrate"
    echo -e "\n1 means iteration,4 means copies,intrate means all actions,copies_intrate means 1,2,4,8,16,32 copies for all copies\n"
    exit 1
}

if [ $EUID -ne 0 ]; then
  echo "Please use sudo to run this script."
  exit 1
fi

if [ "$1" == "log_dir" ];then
	LOG_DIR=$2
	shift
	shift
	ITER=$1
	COPIES=$2
	shift
	shift
	ACTION=$@
	GROUP=1
else
    ITER=$1
    COPIES=$2
    shift
    shift
    ACTION=$@
    LOG_DIR=$WORKLOADS_DIR/log_`date +%Y%m%d_%H%M%S`
fi

if [ ! -e $LOG_DIR ];then
    if [ "$ACTION" != "" ];then
        mkdir -p $LOG_DIR
    fi
fi
SUMMARY=$LOG_DIR/summary.txt

record_info()
{
    if [ $COPIES -ne 1 ];then
	return
    fi

    RES=`grep $1 $SUMMARY`
    if [ "$RES" != "" ];then
	return
    fi

    echo -e "log_dir:$LOG_DIR\n" >> $SUMMARY

    echo -e "\n\n=======$1=======\n\n" >> $SUMMARY

    if [ $1 == "host" ];then
	RES="transparent_hugepage:"`sudo cat /sys/kernel/mm/transparent_hugepage/enabled`"\n\n"
	RES=$RES"\n"`cat /proc/meminfo | grep HugePage`
	RES=$RES"\n PAGESIZE = "`getconf PAGESIZE`
	RES=$RES"\n"`grep "define label" /home/amptest/ampere_spec2017/spec2017/config/ampere_aarch64.cfg`"\n"
    elif [ $1 == "qemu" ];then
	RES="transparent_hugepage:"`ssh_command 3335 'sudo cat /sys/kernel/mm/transparent_hugepage/enabled'`"\n\n"
	RES=$RES"\n\n"`ps aux | grep "qemu.*3335-:22" -m 1`
	RES=$RES"\n\n"`cat /proc/meminfo | grep HugePage`
	RES=$RES"\n\nqemu memory:"`ssh_command 3335 'cat /proc/meminfo | grep HugePage'`
	RES=$RES"\n\nqemu PAGESIZE = "`ssh_command 3335 'getconf PAGESIZE'`
	RES=$RES"\n\n"`ssh_command 3335 'grep "define label" /home/amptest/ampere_spec2017/spec2017/config/ampere_aarch64.cfg'`"\n"
    elif [ $1 == "clh" ];then
	RES="transparent_hugepage:"`ssh_command_ip 192.168.2.2 'sudo cat /sys/kernel/mm/transparent_hugepage/enabled'`"\n\n"
	RES=$RES"\n\n"`ps aux | grep "cloud.*ip=192\.168\.2\.1"`
	RES=$RES"\n\n"`cat /proc/meminfo | grep HugePage`
	RES=$RES"\n\nclh memory:\n"`ssh_command_ip 192.168.2.2 'cat /proc/meminfo | grep HugePage'`
	RES=$RES"\n\nclh PAGESIZE = "`ssh_command_ip 192.168.2.2 'getconf PAGESIZE'`
	RES=$RES"\n\n"`ssh_command_ip 192.168.2.2 'grep "define label" /home/amptest/ampere_spec2017/spec2017/config/ampere_aarch64.cfg'`"\n"
    fi
    echo -e $RES >> $SUMMARY

    rm -rf $WORKLOADS_DIR/current
    ln -s $LOG_DIR $WORKLOADS_DIR/current
}

get_string()
{
    if [ $1 -lt 10 ];then
	echo "0$1"
    else
    echo "$1"
    fi
}

get_cpu_name()
{
    ret=`sudo lscpu | grep -i "AmpereOne"`
    if [ "$ret" != "" ];then
        cpu_name="one"
    fi
    
    ret=`sudo lscpu | grep -i "Altra"`
    if [ "$ret" != "" ];then
        cpu_name="altra"
    fi
}

get_cpu_name

ssh_command()
{
    if [ $# -eq 1 ];then
	sshpass -p $PASS ssh $USER@127.0.0.1 -p 3333 -o "StrictHostKeyChecking no" $1
    else
	sshpass -p $PASS ssh $USER@127.0.0.1 -p $1 -o "StrictHostKeyChecking no" $2
    fi
}

scp_pull()
{
    if [ $# -eq 2 ];then
	sshpass -p $PASS scp -P $PORT -o "StrictHostKeyChecking no" -r $USER@$ADDR:$1 $2
    else
	sshpass -p $PASS scp -P $1    -o "StrictHostKeyChecking no" -r $USER@$ADDR:$2 $3
    fi
}

scp_push()
{
    if [ $# -eq 2 ];then
	sshpass -p $PASS scp -P $PORT -o "StrictHostKeyChecking no" -r $1 $USER@$ADDR:$2
    else
	sshpass -p $PASS scp -P $1    -o "StrictHostKeyChecking no" -r $2 $USER@$ADDR:$3
    fi
}

ping_chs()
{
    ret=0
    for ((i = $vm_start;i < $vm_end;i++))
    do
	ping 192.168.$i.2 -c 1 -W 1
	if [ $? -eq 0 ];then
	    let ret=$ret+1
	fi
    done
    return $ret
}

check_vms_online()
{
    ret=0
    PORT=3333
    let vm_end=$vm_start+$COPIES
    for ((i = $vm_start;i < $vm_end;i++))
    do
	let port=$PORT+$i
        ssh_command $port "ls"
        if [ $? -eq 0 ];then
            let ret=$ret+1
	else
	    break
        fi
    done
    return $ret
}


ssh_command_ch()
{
    sshpass -p $PASS ssh $USER@192.168.2.2 -o "StrictHostKeyChecking no" $1
}

ssh_command_ip()
{
    sshpass -p $PASS ssh $USER@$1 -o "StrictHostKeyChecking no" $2
}

scp_pull_ch()
{
    sshpass -p $PASS scp -o "StrictHostKeyChecking no" -r $USER@192.168.2.2:$1 $2
}

scp_pull_ip()
{
    sshpass -p $PASS scp -o "StrictHostKeyChecking no" -r $USER@$1:$2 $3
}

scp_push_ch()
{
    sshpass -p $PASS scp -o "StrictHostKeyChecking no" -r $1 $USER@192.168.2.2:$2
}

scp_push_ip()
{
    sshpass -p $PASS scp -o "StrictHostKeyChecking no" -r $2 $USER@$1:$3
}

scp_push_chs()
{
    let end=$1+$2
    for ((i = $1;i < $end;i++))
    do
	sshpass -p $PASS scp -o "StrictHostKeyChecking no" -r $3 $USER@192.168.$i.2:$4
    done
}

# Checkout source code of a GIT repo with specified branch and commit
# Args:
#   $1: Target directory
#   $2: GIT URL of the repo
#   $3: Required branch
#   $4: Required commit (optional)
checkout_repo() {
    SRC_DIR="$1"
    GIT_URL="$2"
    GIT_BRANCH="$3"
    GIT_COMMIT="$4"

    # Check whether the local HEAD commit same as the requested commit or not.
    # If commit is not specified, compare local HEAD and remote HEAD.
    # Remove the folder if there is difference.
    if [ -d "$SRC_DIR" ]; then
        pushd $SRC_DIR
        git fetch
        SRC_LOCAL_COMMIT=$(git rev-parse HEAD)
        if [ -z "$GIT_COMMIT" ]; then
            GIT_COMMIT=$(git rev-parse remotes/origin/"$GIT_BRANCH")
        fi
        popd
        if [ "$SRC_LOCAL_COMMIT" != "$GIT_COMMIT" ]; then
            rm -rf "$SRC_DIR"
        fi
    fi

    # Checkout the specified branch and commit (if required)
    if [ ! -d "$SRC_DIR" ]; then
        git clone --depth 1 "$GIT_URL" -b "$GIT_BRANCH" "$SRC_DIR"
        if [ "$GIT_COMMIT" ]; then
            pushd "$SRC_DIR"
            git fetch --depth 1 origin "$GIT_COMMIT"
            git reset --hard FETCH_HEAD
            popd
        fi
    fi
}

build_edk2() {
    EDK2_BUILD_DIR="$WORKLOADS_DIR/edk2_build"
    EDK2_REPO="https://github.com/tianocore/edk2.git"
    EDK2_DIR="$EDK2_BUILD_DIR/edk2"
    EDK2_PLAT_REPO="https://github.com/tianocore/edk2-platforms.git"
    EDK2_PLAT_DIR="$EDK2_BUILD_DIR/edk2-platforms"
    ACPICA_REPO="https://github.com/acpica/acpica.git"
    ACPICA_DIR="$EDK2_BUILD_DIR/acpica"
    export WORKSPACE="$EDK2_BUILD_DIR"
    export PACKAGES_PATH="$EDK2_DIR:$EDK2_PLAT_DIR"
    export IASL_PREFIX="$ACPICA_DIR/generate/unix/bin/"

    if [ ! -d "$EDK2_BUILD_DIR" ]; then
        mkdir -p "$EDK2_BUILD_DIR"
    fi

    # Prepare source code
    checkout_repo "$EDK2_DIR" "$EDK2_REPO" master "46b4606ba23498d3d0e66b53e498eb3d5d592586"
    pushd "$EDK2_DIR"
    git submodule update --init
    popd
    checkout_repo "$EDK2_PLAT_DIR" "$EDK2_PLAT_REPO" master "8227e9e9f6a8aefbd772b40138f835121ccb2307"
    checkout_repo "$ACPICA_DIR" "$ACPICA_REPO" master "b9c69f81a05c45611c91ea9cbce8756078d76233"

    if [[ ! -f "$EDK2_DIR/.built" || \
          ! -f "$EDK2_PLAT_DIR/.built" || \
          ! -f "$ACPICA_DIR/.built" ]]; then
        pushd "$EDK2_BUILD_DIR"
        # Build
        make -C acpica -j `nproc`
        source edk2/edksetup.sh
        make -C edk2/BaseTools -j `nproc`
        build -a AARCH64 -t GCC5 -p ArmVirtPkg/ArmVirtCloudHv.dsc -b RELEASE -n 0
        cp Build/ArmVirtCloudHv-AARCH64/RELEASE_GCC5/FV/CLOUDHV_EFI.fd "$WORKLOADS_DIR"
        touch "$EDK2_DIR"/.built
        touch "$EDK2_PLAT_DIR"/.built
        touch "$ACPICA_DIR"/.built
        popd
    fi
}

mkcloudinit()
{
    pushd $WORKLOADS_DIR
    rm -rf cloudinit*
    mkdir cloudinit
    for ((i = $vm_start; i < $vm_end;i++))
    do
        pushd cloudinit
	addr=`get_string $i`
        echo -e "#cloud-config\nusers:\n  - name: cloud\n    passwd: \$6\$7125787751a8d18a\$sHwGySomUA1PawiNFWVCKYQN.Ec.Wzz0JtPPL1MvzFrkwmop2dq7.4CYf03A5oemPQ4pOFCCrtCelvFBEle/K.\n    sudo: ALL=(ALL) NOPASSWD:ALL\n    lock_passwd: False\n    inactive: False\n    shell: /bin/bash\n\nssh_pwauth: True" > user-data
        echo -e "instance-id: cloud\nlocal-hostname: cloud" > meta-data
        echo -e "version: 2\nethernets:\n  eth0:\n    match:\n       macaddress: 12:34:56:78:90:$addr\n    addresses: [192.168.$i.2/24]\n    gateway4: 192.168.$i.1" > network-config
        mkdosfs -n CIDATA -C cloudinit_$i.img 8192
        mcopy -oi cloudinit_$i.img -s user-data ::
        mcopy -oi cloudinit_$i.img -s meta-data ::
        mkdosfs -n CIDATA -C cloudinit_net_$i.img 8192
        mcopy -oi cloudinit_net_$i.img -s user-data ::
        mcopy -oi cloudinit_net_$i.img -s meta-data ::
        mcopy -oi cloudinit_net_$i.img -s network-config ::
        popd
    done
    popd
}

prepare_spec2017()
{
    ssh_command "ls /home/amptest/ampere_spec2017"
    
    if [ $? -ne 0 ];then
        ssh_command "sudo dnf install -y numactl libxcrypt-compat.aarch64 perf wget"
        ssh_command "sudo mkdir -p /home/amptest"
        ssh_command "cd /home/amptest/ && sudo wget http://10.30.5.24/fromrl/GreenSIR2017/without_report/spec2017_ampere_gcc13_fedora36_siryn_213.tgz"
        ssh_command "sudo tar xf /home/amptest/spec2017_ampere_gcc13_fedora36_siryn_213.tgz -C /home/amptest"
        ssh_command "cd /home/amptest/ampere_spec2017/spec2017 && echo yes | sudo ./install.sh "
        ssh_command "cd /home/amptest/ampere_spec2017/ && sudo ./high_perf.sh "
	ssh_command "sed -i 's/physcpubind=$SPECCOPYNUM/physcpubind=`expr $SPECCOPYNUM + 1`/' /home/amptest/ampere_spec2017/spec2017/config/ampere_aarch64.cfg"
    fi
}

prepare_disks()
{
    addr=`get_string $1`
    echo cp $WORKLOADS_DIR/Fedora-Cloud-Base-38-1.6.aarch64.raw $DISKS_DIR/Fedora-Cloud-Base-38-1.6.aarch64_$addr.raw
    cp -f $WORKLOADS_DIR/Fedora-Cloud-Base-38-1.6.aarch64.raw $DISKS_DIR/Fedora-Cloud-Base-38-1.6.aarch64_$addr.raw
    qemu-img create -f qcow2 -b $WORKLOADS_DIR/spec2017_disk.qcow2 -F qcow2 $DISKS_DIR/spec2017_disk_$addr.qcow2
}

start_perf()
{
    DIR="COPY"`get_string $COPIES`
    csv_name=$LOG_DIR/$DIR/$1_`echo $ACTION|sed 's/ /_/g'`/$1.csv

    if [ "$1" != "host" ];then
        if [ $cpu_name == "one" ];then
            perf stat -C 3 -e cycles:G,cycles:H,instructions:G,stall_backend:G,stall_frontend:G,STALL_BACKEND_TLB:G,STALL_BACKEND_CACHE:G,STALL_BACKEND_MEM:G,mem_access:G,l1d_tlb:G,l1d_tlb_refill:G,l2d_tlb:G,l2d_tlb_refill:G,dtlb_walk:G,rd80d:G,stall_slot_backend:G,op_spec:G,op_retired:G,STALL_BACKEND_RESOURCE:G -I 1000 -x , -o $csv_name &
        fi
        if [ $cpu_name == "altra" ];then
            perf stat -C 3 -e cycles:G,cycles:H,instructions:G,stall_backend:G,stall_frontend:G,mem_access:G,l2d_tlb:G,l2d_tlb_refill:G,dtlb_walk:G,inst_spec:G,inst_retired:G -I 1000 -x , -o $csv_name &
        fi
    else
        if [ $cpu_name == "one" ];then
            perf stat -C 3 -e cycles,instructions,stall_backend,stall_frontend,STALL_BACKEND_TLB,STALL_BACKEND_CACHE,STALL_BACKEND_MEM,mem_access,l1d_tlb,l1d_tlb_refill,l2d_tlb,l2d_tlb_refill,dtlb_walk,rd80d,stall_slot_backend,op_spec,op_retired,STALL_BACKEND_RESOURCE -I 1000 -x , -o $csv_name &
        fi
    
        if [ $cpu_name == "altra" ];then
            perf stat -C 3 -e cycles,instructions,stall_backend,stall_frontend,mem_access,l2d_tlb,l2d_tlb_refill,dtlb_walk,inst_spec,inst_retired -I 1000 -x , -o $csv_name &
        fi
    fi
}

if [ "$1" == "build_edk2" ];then
    rm -rf /root/workloads/edk2_build
    source scripts/common-aarch64.sh
    source scripts/test-util.sh
    build_edk2
elif [ "$1" == "clear" ];then
    rm $WORKLOADS_DIR/*.csv
    rm $WORKLOADS_DIR/*.txt
    rm -r $WORKLOADS_DIR/*result*
fi
