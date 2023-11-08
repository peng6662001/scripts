#!/bin/bash -x
ADDR=127.0.0.1
PORT=3333
USER=cloud
PASS=cloud123
cpu_name="host"
WORKLOADS_DIR=$PWD/workloads
LOG_DIR=$WORKLOADS_DIR/latest


if [ "$1" == "log_dir" ];then
	LOG_DIR=$2
	shift
	shift
	ITER=$1
	COPIES=$2
	shift
	shift
	ACTION=$@
else
    ITER=$1
    COPIES=$2
    shift
    shift
    ACTION=$@
    LOG_DIR=$WORKLOADS_DIR/log_`echo $ACTION|sed 's/ /_/g'`_`date +%Y%m%d_%H%M%S`
fi

if [ ! -e $LOG_DIR ];then
    if [ "$ACTION" != "" ];then
        mkdir -p $LOG_DIR
    fi
fi

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

showHelp()
{
    device=$1
    echo -e "\nusage:"
    echo "./${device}_spec2017.sh 1 4 500.perlbench_r 502.gcc_r 505.mcf_r 520.omnetpp_r 523.xalancbmk_r 525.x264_r 531.deepsjeng_r 541.leela_r 548.exchange2_r 557.xz_r"
    echo "./${device}_spec2017.sh 1 4 intrate"
    echo "./${device}_spec2017.sh 1 4 copies_intrate"
    echo -e "\n1 means iteration,4 means copies,intrate means all actions,copies_intrate means 1,2,4,8,16,32 copies for all copies\n"
}

ssh_command()
{
    sshpass -p $PASS ssh $USER@127.0.0.1 -p 3333 -o "StrictHostKeyChecking no" $1
}

scp_pull()
{
    sshpass -p $PASS scp -P $PORT -o "StrictHostKeyChecking no" -r $USER@$ADDR:$1 $2
}

scp_push()
{
    sshpass -p $PASS scp -P $PORT -o "StrictHostKeyChecking no" -r $1 $USER@$ADDR:$2
}

ssh_command_ch()
{
    sshpass -p $PASS ssh $USER@192.168.249.2 -o "StrictHostKeyChecking no" $1
}

scp_pull_ch()
{
    sshpass -p $PASS scp -o "StrictHostKeyChecking no" -r $USER@192.168.249.2:$1 $2
}

scp_push_ch()
{
    sshpass -p $PASS scp -o "StrictHostKeyChecking no" -r $1 $USER@192.168.249.2:$2
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
    rm -rf cloudinit*
    mkdir cloudinit
    pushd cloudinit
    echo -e "#cloud-config\nusers:\n  - name: cloud\n    passwd: \$6\$7125787751a8d18a\$sHwGySomUA1PawiNFWVCKYQN.Ec.Wzz0JtPPL1MvzFrkwmop2dq7.4CYf03A5oemPQ4pOFCCrtCelvFBEle/K.\n    sudo: ALL=(ALL) NOPASSWD:ALL\n    lock_passwd: False\n    inactive: False\n    shell: /bin/bash\n\nssh_pwauth: True" > user-data
    echo -e "instance-id: cloud\nlocal-hostname: cloud" > meta-data
    echo -e "version: 2\nethernets:\n  eth0:\n    match:\n       macaddress: 12:34:56:78:90:ab\n    addresses: [192.168.249.2/24]\n    gateway4: 192.168.249.1" > network-config
    mkdosfs -n CIDATA -C cloudinit.img 8192
    mcopy -oi cloudinit.img -s user-data ::
    mcopy -oi cloudinit.img -s meta-data ::
    mkdosfs -n CIDATA -C cloudinit_net.img 8192
    mcopy -oi cloudinit_net.img -s user-data ::
    mcopy -oi cloudinit_net.img -s meta-data ::
    mcopy -oi cloudinit_net.img -s network-config ::
    
    popd
}

preprare_spec2017()
{
    ssh_command "ls /home/amptest/ampere_spec2017"
    
    if [ $? -ne 0 ];then
        ssh_command "sudo dnf install -y numactl libxcrypt-compat.aarch64 perf wget"
        ssh_command "sudo mkdir -p /home/amptest"
        ssh_command "cd /home/amptest/ && sudo wget http://10.30.5.24/fromrl/GreenSIR2017/without_report/spec2017_ampere_gcc13_fedora36_siryn_213.tgz"
        ssh_command "sudo tar xf /home/amptest/spec2017_ampere_gcc13_fedora36_siryn_213.tgz -C /home/amptest"
        ssh_command "cd /home/amptest/ampere_spec2017/spec2017 && echo yes | sudo ./install.sh "
        ssh_command "cd /home/amptest/ampere_spec2017/ && sudo ./high_perf.sh "
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
