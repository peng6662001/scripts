#!/bin/bash 

#2023.01.10 version 1.0

source command.sh
if [ ! -e $WORKLOADS_DIR ];then
  mkdir $WORKLOADS_DIR
fi

ROOTFS="$WORKLOADS_DIR/Fedora-Cloud-Base-38-1.6.aarch64.raw"

build_kernel() {
  if [ -e linux-cloud-hypervisor/arch/arm64/boot/Image ];then
    return 0
  else
    rm -rf linux-cloud-hypervisor
  fi
  git clone --depth 1 https://github.com/cloud-hypervisor/linux.git linux-cloud-hypervisor
  pushd linux-cloud-hypervisor
  wget https://raw.githubusercontent.com/cloud-hypervisor/cloud-hypervisor/main/resources/linux-config-aarch64
  cp linux-config-aarch64 .config # AArch64
  echo "Y y" | make -j `nproc`
  popd
}

build_edk2()
{
    if [ -e $WORKLOADS_DIR/CLOUDHV_EFI.fd ];then
	return
    fi
    cp command.sh $WORKLOADS_DIR/cloud-hypervisor/

    pushd $WORKLOADS_DIR/cloud-hypervisor
    service docker start
    ./scripts/dev_cli.sh tests --integration -- --test-filter test_virtio_iommu

    docker run --workdir /cloud-hypervisor --rm --privileged --security-opt seccomp=unconfined --ipc=host --net=bridge --mount type=tmpfs,destination=/tmp --volume /dev:/dev --volume $PWD:/cloud-hypervisor --volume /root/workloads:/root/workloads --env USER=root --env CH_LIBC=gnu ghcr.io/cloud-hypervisor/cloud-hypervisor:20230804-0 dbus-run-session ./command.sh build_edk2
    popd
    cp /root/workloads/edk2_build/Build/ArmVirtCloudHv-AARCH64/RELEASE_GCC5/FV/CLOUDHV_EFI.fd $WORKLOADS_DIR/
}

if [ ! -e /sys/fs/cgroup/systemd ];then
  sudo mkdir /sys/fs/cgroup/systemd
  sudo mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd
fi

sudo apt install -y git build-essential m4 bison flex uuid-dev qemu-utils cargo mtools

rustc --version
if [ $? -ne 0 ];then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh 
  
  rustup target add aarch64-unknown-linux-musl # AArch64
fi

pushd $WORKLOADS_DIR

#build_kernel

if [ ! -e cloud-hypervisor ];then
  git clone https://github.com/cloud-hypervisor/cloud-hypervisor.git
  pushd cloud-hypervisor
  git reset 12120c2e3e0f75c786021c7ee461a342901791db --hard
  popd
fi

cd cloud-hypervisor

if [ ! -e target/release/cloud-hypervisor ];then
  cargo build --release
fi
popd

build_edk2
rm -rf /tmp/vsock

ssh-keygen -f "/root/.ssh/known_hosts" -R "192.168.249.2"
rm -rf /dev/hugepages1G/libvirt/qemu/1-test
./setup_1g_hugepage.sh

$WORKLOADS_DIR/cloud-hypervisor/target/release/cloud-hypervisor \
        --cpus boot=40,affinity=[0@[1],1@[2],2@[3],3@[4],4@[5],5@[6],6@[7],7@[8],8@[9],9@[10],10@[11],11@[12],12@[13],13@[14],14@[15],15@[16],16@[17],17@[18],18@[19],19@[20],20@[21],21@[22],22@[23],23@[24],24@[25],25@[26],26@[27],27@[28],28@[29],29@[30],30@[31],31@[32],32@[33],33@[34],34@[35],35@[36],36@[37],37@[38],38@[39],39@[40]] \
        --memory size=128G,hugepages=on,hugepage_size=1G,prefault=on \
        --kernel $WORKLOADS_DIR/CLOUDHV_EFI.fd \
        --disk path=$WORKLOADS_DIR/Fedora-Cloud-Base-38-1.6.aarch64_02.raw \
        --disk path=$WORKLOADS_DIR/spec2017_disk.qcow2 \
        --disk path=$WORKLOADS_DIR/cloudinit/cloudinit_net_2.img,iommu=on \
        --vsock cid=3,socket=/tmp/vsock \
	--serial tty --console off \
        --net id=net123,tap=,mac=12:34:56:78:90:ab,ip=192.168.249.1,mask=255.255.255.0 & #& exit
sed -i '/192.168.249.2/d' /root/.ssh/known_hosts
res=1
while [ $res -ne 0 ];
do
    ssh_command_ch ls
    res=$?
    sleep 1
done

