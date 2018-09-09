#!/bin/bash

set -eu
set -o pipefail

#mount -t hugetlbfs hugetlbfs /mnt/hugepages1
#/usr/local/bin/hugetlb-reserve-pages 8 node1

#nice -n -20 \
qemu-system-x86_64 \
    -nodefaults \
    -enable-kvm \
    -name guestseat \
    -name debug-threads=on \
    -machine q35 \
    -cpu host \
    -smp 4,sockets=1,cores=4,threads=1 \
    -m 8192 \
    -mem-path /mnt/hugepages1 \
    -mem-prealloc \
    -device vfio-pci,host=08:00.0,x-vga=on \
    -device vfio-pci,host=08:00.1 \
    -device vfio-pci,host=07:00.0 \
    -object iothread,id=io0 \
    -drive if=pflash,format=raw,readonly,file=/usr/share/ovmf/x64/OVMF_CODE.fd \
    -drive if=pflash,format=raw,file=/opt/qemu-vm/bios/seat-ovmf-vars.fd \
    -drive file=/opt/qemu-vm/disks/seat-ubuntu.qcow2,id=disk,format=qcow2,if=none,cache=none,cache.direct=on,aio=native \
    -device virtio-scsi-pci \
    -device scsi-hd,drive=disk \
    -boot dc \
    -netdev tap,id=net0,ifname=tap1,script=no,downscript=no,vhost=on \
    -device virtio-net-pci,netdev=net0,mac="DE:AD:BE:EF:BA:BE" \
    -vga none \
    -serial none \
    -parallel none \
    -balloon none \
    -display none \
    -nographic \
    -daemonize


#qemupid=$(ps axf | grep guestseat | grep -v grep | awk '{print $1}')

# pin vm threads to isolcpus, and workers (-w) to non-isol, node1 threads 
#/usr/local/bin/qemu-cpuaffinity -p "$qemupid" -c 8,9,10,11 -i 12 -q 12 -w 13 

