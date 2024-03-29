#!/bin/bash

WORKLOADS_DIR="../workloads"

ssh-keygen -f "/root/.ssh/known_hosts" -R "192.168.2.2"
#cp $WORKLOADS_DIR/Fedora-Cloud-Base-38-1.6.aarch64.raw $WORKLOADS_DIR/Fedora-Cloud-Base-38-1.6.aarch64_new.raw
$WORKLOADS_DIR/cloud-hypervisor/target/release/cloud-hypervisor \
        --cpus boot=1 \
        --memory size=4G,hugepages=on,hugepage_size=1G,prefault=on \
        --kernel $WORKLOADS_DIR/CLOUDHV_EFI.fd \
        --disk path=/home/dom/images/jammy-server-cloudimg-arm64-custom-20220329-0.qcow2 \
        --disk path=$WORKLOADS_DIR/cloudinit/cloudinit_net_2.img,iommu=on \
        --disk path=$WORKLOADS_DIR/disks/spec2017_disk_02.qcow2 \
        --vsock cid=2,socket=/tmp/vsock_2 \
        --serial tty --console off \
        --net id=net_2,tap=,mac=12:34:56:78:90:02,ip=192.168.2.1,mask=255.255.255.0
