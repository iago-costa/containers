## Create a qcow2 disk
```bash
qemu-img create -f qcow2 img1.cow 20G
```

## Run qemu first installation with kvm
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

## Run image
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

## show backing chain info of qcow2 image 
qemu-img info --backing-chain input_image.qcow2; 

## Hugepages
```bash
sudo su
echo 1050 > /proc/sys/vm/nr_hugepages
cat vim /proc/sys/vm/nr_hugepages
```

## Keybindgs qemu window
```
control + alt + G - toggle mouse mode
control + alt + F - toggle fullscreen
```

## Internal networking
```bash
# iptables allow packets in a bridged network
iptables -I FORWARD -m physdev --physdev-is-bridged -j ACCEPT
# Show macs in bridge
sudo brctl showmacs mynet0
# Get ips in use
nmap -sn 192.168.0.1/24
```


## Install Kubernetes in ClearOS
```bash
- (kubernetes)[https://www.clearlinux.org/clear-linux-documentation/tutorials/kubernetes.html]

```bash
hostnamectl set-hostname
sudo swupd update
sudo swupd bundle-add network-basic
sudo swupd bundle-add cloud-native-basic
```


## Init k8s
```bash
sudo kubeadm init \
--apiserver-advertise-address=<ip> \
--cri-socket=/run/containerd/containerd.sock \
--pod-network-cidr 10.244.0.0/16

sudo kubeadm init \
--apiserver-advertise-address=158.101.13.67 \
--cri-socket=/run/containerd/containerd.sock \
--pod-network-cidr=10.244.0.0/16

sudo kubeadm init \
--cri-socket=/run/containerd/containerd.sock \
--pod-network-cidr 10.244.0.0/16
```

## Reset k8s
```bash
sudo kubeadm reset -f || true
sudo rm -rf $HOME/.kube/config || true
sudo rm -rf /etc/cni/net.d || true
```

## kubeadm start/join
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.0.136:6443 --token u7ijie.ld8g9uk41nrtwxij \
        --discovery-token-ca-cert-hash sha256:85a6729ae9f2476367c263d22e4028eb37146511bbb7d7991635ecdb9ed65c9c

cat $HOME/.kube/config

```bash
kubeadm token create --print-join-command
```

## Check nodes/pods status (K8s)
kubectl get pods -n kube-system
kubectl describe node


## Config Container Network Interface (CNI)
1. Up to date flannel cni config 
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

mkdir -p /opt/cni/bin
curl -O -L https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz
tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-v1.2.0.tgz


2. Outdated weave cni config
kubectl apply -f "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s-1.11.yaml"
kubectl delete -f "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s-1.11.yaml"


## Logs kubelet
```bash
journalctl -u kubelet

sudo swapoff -a
sudo rm /var/swapfile
```

## Activate ssh in master node
1. Generate ssh key and set config
```bash
cd $HOME/.ssh/
ssh-keygen -t rsa
cat id_rsa.pub | xclip -sel clip
# Set config
nvim config
```
2. Copy pub key to VM
```bash
#### paste the pub key
vim $HOME/.ssh/authorized_keys
# Set config
cat << EOF | sudo tee /etc/ssh/sshd_config
Port 22
PasswordAuthentication no
AllowAgentForwarding yes
ChallengeResponseAuthentication no
EOF
# Enable file config
vim /usr/lib/systemd/system/sshd.service
# Restart sshd
systemctl restart sshd
```

## Copy kube config to local
```bash
scp -O master-k8s-1:/root/.kube/config "config"
```

## nmap scan
```bash
sudo nmap -snP 192.168.0.1/24
sudo nmap -p1-65535 -sV -sS -T4 192.168.0.1/24
```

