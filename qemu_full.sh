#!/bin/bash -x

source command.sh
if [ ! -d $WORKLOADS_DIR ];then
    mkdir $WORKLOADS_DIR
fi

pushd $WORKLOADS_DIR

BIOS_BIN="edk2/Build/ArmVirtQemu-AARCH64/RELEASE_GCC5/FV/QEMU_EFI.fd"
QEMU_BIN="qemu/build/qemu-system-aarch64"
QEMU_IMG="qemu/build/qemu-img"
ROOTFS="Fedora-Cloud-Base-38-1.6.aarch64.raw"
KERNEL="linux/arch/arm64/boot/Image"

get_source() {
	if [ -e "$2" ]; then
		# source exits, reset source
		pushd $2
		#git reset --hard HEAD
		popd
		return 0
	fi
    
    while true
    do
        echo "git clone --depth 1 $1 $2"
        #ret = `git clone --depth 1 $1 $2 || exit 1`
        git clone --depth 1 $1 $2
        ret=$?
        echo "ret = $ret"
    
        if [ "$ret" = "" ];then
            break
        fi
    
        if [ $ret -eq 0 ];then
            break
        fi
    done

	return 0
}

BIOS_BIN="edk2/Build/ArmVirtQemu-AARCH64/RELEASE_GCC5/FV/QEMU_EFI.fd"
# build edk2 bios
if [ ! -f $BIOS_BIN ]; then
	get_source https://git.linaro.org/uefi/uefi-tools.git uefi-tools
	get_source https://github.com/tianocore/edk2.git edk2 46b4606ba23498d3d0e66b53e498eb3d5d592586
	pushd edk2
	git submodule update --init || exit 1
	../uefi-tools/edk2-build.sh -e . armvirtqemu64 || exit 1
	popd
fi

# build qemu
QEMU_BIN="qemu/build/qemu-system-aarch64"
if [ ! -f $QEMU_BIN ]; then
	get_source https://git.qemu.org/git/qemu.git qemu
	pushd qemu
	./configure --target-list=aarch64-softmmu --disable-docs || exit 1
	make -j || exit 1
	popd
fi

# download debian rootfs
QEMU_IMG="qemu/build/qemu-img"
while [ ! -f $ROOTFS ];
do
	wget https://download.fedoraproject.org/pub/fedora/linux/releases/38/Cloud/aarch64/images/Fedora-Cloud-Base-38-1.6.aarch64.raw.xz || exit 1
	xz -dk Fedora-Cloud-Base-38-1.6.aarch64.raw.xz
	$QEMU_IMG resize Fedora-Cloud-Base-38-1.6.aarch64.raw +80G
	sleep 1
done

# build kernel
KERNEL="linux/arch/arm64/boot/Image"
if [ ! -f $KERNEL ]; then
	get_source https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git linux
	pushd linux
	echo "CONFIG_LIBNVDIMM=y" >> arch/arm64/configs/defconfig
	echo "CONFIG_CXL_BUS=y" >> arch/arm64/configs/defconfig
	echo "CONFIG_CXL_MEM=y" >> arch/arm64/configs/defconfig
	echo "CONFIG_ACPI_HMAT=y" >> arch/arm64/configs/defconfig
	echo "CONFIG_ACPI_HOTPLUG_MEMORY=y" >> arch/arm64/configs/defconfig
	echo "CONFIG_MEMORY_HOTPLUG=y" >> arch/arm64/configs/defconfig
	echo "CONFIG_MEMORY_HOTPLUG_DEFAULT_ONLINE=y" >> arch/arm64/configs/defconfig
	echo "CONFIG_DYNAMIC_DEBUG=y" >> arch/arm64/configs/defconfig
	make defconfig || exit 1
	make -j || exit 1
	#make -C . M=./tools/testing/cxl
	popd
fi

mkcloudinit

popd

sed -i '/127.0.0.1/d' /root/.ssh/known_hosts

QEMU_BIN="$WORKLOADS_DIR/qemu/build/qemu-system-aarch64"
BIOS_BIN="/usr/share/edk2/aarch64/QEMU_EFI.silent.fd"
DISK0_CFG="-drive if=none,file=$WORKLOADS_DIR/Fedora-Cloud-Base-38-1.6.aarch64.raw,format=raw,id=hd1 -device virtio-blk-pci,drive=hd1,bootindex=0"
DISK1_CFG="-drive if=none,file=$WORKLOADS_DIR/cloudinit/cloudinit_net.img,format=raw,id=hd2 -device virtio-blk-pci,drive=hd2,bootindex=1"
qemu-system-aarch64 --version
qemu-system-aarch64 \
        -nographic \
        -machine virt,gic-version=max -enable-kvm\
        -bios $BIOS_BIN \
        -cpu max -smp cpus=40 \
        -m 128G \
	-qmp unix:/tmp/qmp-test2,server,nowait \
        $DISK0_CFG \
        $DISK1_CFG \
        -net nic -net user,hostfwd=tcp::3333-:22 \
        2>&1 | tee $WORKLOADS_DIR/log.txt & 
