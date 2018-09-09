#!/bin/bash

set -eu
set -o pipefail

# iothread=io0
# reserve 8GB of hugepages from NUMA node0
mount -t hugetlbfs hugetlbfs /mnt/hugepages
hugetlb-reserve-pages 8 node0

nice -n -20 \
qemu-system-x86_64 \
    -nodefaults \
    -enable-kvm \
    -name gameserver \
    -name debug-threads=on \
    -machine q35 \
    -cpu host,kvm=off,hv_time,hv_relaxed,hv_vapic,hv_vpindex,hv_reset,hv_runtime,hv_crash,hv_synic,hv_stimer,hv_spinlocks=0x1fff,hv_vendor_id=Void,-hypervisor \
    -smp 4,sockets=1,cores=4,threads=1 \
    -m 8192 \
    -mem-path /mnt/hugepages \
    -mem-prealloc \
    -device vfio-pci,host=03:00.0,x-vga=on \
    -device vfio-pci,host=03:00.1 \
    -device vfio-pci,host=07:00.0 \
    -object iothread,id=io0 \
    -device virtio-scsi-pci,iothread=io0 \
    -drive file=/dev/sda2,id=disk1,format=raw,if=virtio,cache=none,cache.direct=on,aio=threads \
    -netdev tap,id=net0,ifname=tap0,script=no,downscript=no,vhost=on \
    -device virtio-net-pci,netdev=net0 \
    -serial none \
    -parallel none \
    -balloon none \
    -vga none \
    -nographic \
    -no-hpet \
    -daemonize


#    -device vfio-pci,host=07:00.0 \
#    -device scsi-hd,drive=disk0 \
#    -drive file=/opt/qemu-vm/disks/game2.raw,id=disk0,format=raw,if=none,cache=none,cache.direct=on,aio=threads \



#    -drive format=raw,readonly,media=cdrom,file=/opt/qemu-vm/disks/windows10.iso \
#    -drive format=raw,readonly,media=cdrom,file=/opt/qemu-vm/disks/win-virtio.iso \


#    -device scsi-hd,drive=disk1,bootindex=0 \

#    -device ide-drive,drive=disk0,bus=ide.0 \
#    -drive file=/dev/sda2,id=disk0,format=raw,if=none,cache=none,aio=native,cache.direct=on \


#    -drive file=/opt/qemu-vm/disks/game.qcow2,id=disk0,format=qcow2,if=none,cache=none \

#    -net nic,model=virtio,macaddr="DE:AD:BE:EF:E4:B1" \
#    -net tap,ifname=tap0,script=no,downscript=no,vhost=on \


#    -drive format=raw,readonly,media=cdrom,file=/opt/qemu-vm/disks/en_windows_server_2016_x64_desktop.iso \

#    -drive if=pflash,format=raw,readonly,file=/usr/share/ovmf/x64/OVMF_CODE.fd \
#    -drive if=pflash,format=raw,file=/opt/qemu-vm/bios/game-ovmf-vars.fd \


qemupid="$(ps axf | grep gameserver | grep -v grep | awk '{print $1}')"

# pin vm threads to isolcpus, and workers (-w) to non-isol, node0 threads 
qemu-cpuaffinity -p $qemupid -c 0,1,2,3 -i 5 -q 4 -w '6-7'

# service interrupts coming from vfio devices on the VM's cores
for i in $(cat /proc/interrupts | grep vfio | awk '{print $1}' | tr -d :); do
     echo 0-3 > /proc/irq/$i/smp_affinity_list;
done;

