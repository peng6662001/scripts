#!/bin/bash -x
DISK0_CFG="-drive if=none,file=../workloads/Fedora-Cloud-Base-38-1.6.aarch64.raw,format=raw,id=hd1 -device virtio-blk-pci,drive=hd1,bootindex=0"
DISK1_CFG="-drive if=none,file=../workloads/cloudinit/cloudinit_2.img,format=raw,id=hd2 -device virtio-blk-pci,drive=hd2,bootindex=1"
DISK2_CFG="-drive if=none,file=../workloads/spec2017_disk.qcow2,format=qcow2,id=hd3 -device virtio-blk-pci,drive=hd3,bootindex=2"
qemu-system-aarch64 --version
qemu-system-aarch64 \
	-nographic \
        -machine virt,gic-version=max -enable-kvm\
	-bios QEMU_EFI.fd \
        -cpu max -smp cpus=40 \
	-m 128G \
	"${KERNEL_CFG[@]}" \
	$DISK0_CFG \
	$DISK1_CFG \
	$DISK2_CFG \
	-net nic -net user,hostfwd=tcp::2223-:22 \
#	-nic tap,mac=02:ca:fe:f0:0d:01 \
	

	#-monitor unix:/tmp/qmp-test,server,nowait \
        #-qmp unix:/tmp/qmp-test2,server,nowait 2>&1 | tee log.txt 
#-net nic -net user,hostfwd=tcp::2223-:22 \
