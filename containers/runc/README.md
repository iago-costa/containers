

```bash
runc spec && cat config.json
wget http://dl-cdn.alpinelinux.org/alpine/v3.10/releases/x86_64/alpine-minirootfs-3.10.1-x86_64.tar.gz
mkdir rootfs && tar -xzf \
    alpine-minirootfs-3.10.1-x86_64.tar.gz -C rootfs
runc create --help


sudo su -
mkdir bundle && mv config.json ./bundle && mv rootfs ./bundle;
chown -R $(id -u) bundle

go install github.com/opencontainers/runc/contrib/cmd/recvtty@latest
recvtty tty.sock
sudo runc create -b bundle --console-socket $(pwd)/tty.sock container-crypt0n1t3
sudo runc list
ps aux | grep 86087
sudo ls -al /proc/86087/ns
sudo ls -al /proc/$$/ns

sudo nsenter --target 86087 --net
ifconfig -a

sudo ip link add veth0 type veth peer name ceth0
sudo ip link set veth0 up
sudo ip addr add 172.12.0.11/24 dev veth0
sudo ip link set ceth0 netns /proc/86087/ns/net

sudo nsenter --target 86087 --net
ifconfig -a

ip link set lo up
ip link set ceth0 up
ip addr add 172.12.0.12/24 dev ceth0
ping -c 1 172.12.0.11

sudo runc start container-crypt0n1t3
ps aux | grep 86087
sudo runc list

recvtty tty.sock
ls
ifconfig -a
id
ps aux

mount

sudo runc  pause container-crypt0n1t3
sudo sudo runc list

sudo sudo runc resume container-crypt0n1t3
ps aux | grep 86087

strace sudo runc  pause container-crypt0n1t3
sudo runc events container-crypt0n1t3

cat /sys/fs/cgroup/memory/user.slice/user-1000.slice/user@1000.service/container-crypt0n1t3/memory.limit_in_bytes
cat /sys/fs/cgroup/cpuset/container-crypt0n1t3/cpuset.cpus

sudo runc run -b bundle -d --console-socket $(pwd)/tty.sock container-printer
sudo runc checkpoint --image-path $(pwd)/image-checkpoint \
 container-printer
ls image-checkpoint

sudo runc restore --detach --image-path $(pwd)/image-checkpoint \
-b bundle --console-socket $(pwd)/tty.sock container-printer-restore

sudo runc exec container-crypt0n1t3-restore sleep 120

sudo runc list
sudo runc ps container-crypt0n1t3-restore


```


## References:
    - https://man7.org/linux/man-pages/man1/unshare.1.html
    - https://blog.quarkslab.com/digging-into-runtimes-runc.html

