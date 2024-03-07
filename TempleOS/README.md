- Create a qcow2 disk
```bash
qemu-img create -f qcow2 img1.cow 20G
```

- Run qemu first installation with kvm
```bash
sudo qemu-system-x86_64 \
    -enable-kvm \
    -cpu host \
    -m 2048 \
    -cdrom ${ISO} \
    -boot order=d \
    -device virtio-net-pci,netdev=${BRIDGE} \
    -netdev tap,id=${BRIDGE},ifname=${TAP},script=no,downscript=no,vhost=on \
    -drive file=${IMAGE},format=qcow2
```

- Run image
```bash
sudo qemu-system-x86_64 \
    -enable-kvm \
    -smp sockets=1,cpus=4,cores=2 -cpu host \
    -m 2048 \
    -vga none -nographic \
    -device virtio-net-pci,netdev=${BRIDGE} \
    -netdev tap,id=${BRIDGE},ifname=${TAP},script=no,downscript=no,vhost=on \
    -debugcon file:${IMAGE}.log \
    ${IMAGE}
```

## Hugepages
```bash
sudo su
echo 1050 > /proc/sys/vm/nr_hugepages
cat vim /proc/sys/vm/nr_hugepages
```

- Keybindgs qemu window
```
control + alt + G - toggle mouse mode
control + alt + F - toggle fullscreen
```

- Internal networking
```bash
# iptables allow packets in a bridged network
iptables -I FORWARD -m physdev --physdev-is-bridged -j ACCEPT
# Show macs in bridge
sudo brctl showmacs mynet0
# Get ips in use
nmap -sn 192.168.0.1/24
```


