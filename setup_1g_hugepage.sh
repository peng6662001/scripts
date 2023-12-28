# script to setup 336 1G huge pages size

is_huge1g=`mount | grep hugepages1G`
if [ "$is_huge1g" == "" ] ; then
    echo "start following only once after each reboot"

    echo "Mounting hugetlbfs /dev/hugepages1G ..."
    mkdir /dev/hugepages1G
    mount -t hugetlbfs -o pagesize=1G none /dev/hugepages1G 
    systemctl restart libvirtd

    sleep 2

    echo "Allocating 336 hugepages of size 1GB..."
    echo 336 > /sys/devices/system/node/node0/hugepages/hugepages-1048576kB/nr_hugepages
else
        echo -e "1G Hugepage mounted: \n\t$is_huge1g"
fi

echo "Verifying boot command line with 256 1G-hugepages specified :"
echo -e "\t`cat /proc/cmdline`"

echo "After VM running, run following command to verify 1G huge page: "
echo -e '\tfor q in $(pgrep qemu); do grep kernelpagesize_kB=1 /proc/$q/numa_maps; done'

