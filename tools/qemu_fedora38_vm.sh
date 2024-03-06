#!/bin/bash 


qemu-system-aarch64 -nographic -machine virt,gic-version=max -enable-kvm \
    -bios /usr/share/edk2/aarch64/QEMU_EFI.silent.fd \
    -cpu max -smp cpus=1 -m 4G -qmp unix:/tmp/qmp-test03,server,nowait \
    -drive if=none,file=/home/dom/scripts/workloads/disks/Fedora-Cloud-Base-38-1.6.aarch64_32.raw,format=raw,id=hd1 \
    -device virtio-blk-pci,drive=hd1,bootindex=0 \
    -drive if=none,file=/home/dom/scripts/workloads/cloudinit/cloudinit_3.img,format=raw,id=hd2 \
    -device virtio-blk-pci,drive=hd2,bootindex=1 \
    -drive if=none,file=/home/dom/scripts/workloads/disks/spec2017_disk_32.qcow2,format=qcow2,id=hd3 \
    -device virtio-blk-pci,drive=hd3,bootindex=2 \
    -net nic -net user,hostfwd=tcp::3336-:22
