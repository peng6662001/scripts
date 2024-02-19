#!/bin/bash  

#2023.01.10 version 1.0

source command.sh

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

cp $WORKLOADS_DIR/Fedora-Cloud-Base-38-1.6.aarch64_rebuild.raw $WORKLOADS_DIR/Fedora-Cloud-Base-38-1.6.aarch64_clh.raw
qemu-img create -f qcow2 -b $WORKLOADS_DIR/spec2017_disk.qcow2 -F qcow2 $WORKLOADS_DIR/spec2017_disk_clh.qcow2

$WORKLOADS_DIR/cloud-hypervisor/target/release/cloud-hypervisor \
        --cpus boot=40,affinity=[0@[81],1@[82],2@[83],3@[84],4@[85],5@[86],6@[87],7@[88],8@[89],9@[90],10@[91],11@[92],12@[93],13@[94],14@[95],15@[96],16@[97],17@[98],18@[99],19@[100],20@[101],21@[102],22@[103],23@[104],24@[105],25@[106],26@[107],27@[108],28@[109],29@[110],30@[111],31@[112],32@[113],33@[114],34@[115],35@[116],36@[117],37@[118],38@[119],39@[120]] \
        --memory size=128G,hugepages=on,hugepage_size=1G,prefault=on \
        --kernel $WORKLOADS_DIR/CLOUDHV_EFI.fd \
        --disk path=$WORKLOADS_DIR/Fedora-Cloud-Base-38-1.6.aarch64_clh.raw \
        --disk path=$WORKLOADS_DIR/cloud_init_clh.img,iommu=on \
        --disk path=$WORKLOADS_DIR/spec2017_disk_clh.qcow2 \
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

