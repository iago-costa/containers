#!/bin/bash

# k8s with containerd

# Configure required modules
# First, load two modules in the current running environment and configure them to load on boot.
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set ipv4 forwarding
echo '1' > /proc/sys/net/ipv4/ip_forward

# Configure required sysctl to persist across system reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo mkdir -p /etc/sysctl.d/
sudo tee /etc/sysctl.d/99-kubernetes-cri.conf > /dev/null <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Install containerd packages
# As of this writing, the containerd package included in the default Ubuntu repositories stops at 1.5.9. To bootstrap a cluster on a modern version of Kubernetes, you will need container 1.6+. To get 1.6+ you’ll need to get the containerd package from the docker repository.
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update 
sudo apt-get install -y containerd.io

# Create a containerd configuration file
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Set the cgroup driver for runc to systemd
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Apply sysctl params without reboot
sudo sysctl --system

# Restart containerd
sudo systemctl restart containerd

# Disable swap
sudo systemctl mask $(sed -n -e 's#^/var/\([0-9a-z]*\).*#var-\1.swap#p' /proc/swaps) 2>/dev/null
sudo swapoff -a

# Set host
echo "127.0.0.1 localhost `hostname`" | sudo tee --append /etc/hosts

# Enable kubelet
sudo systemctl enable kubelet.service

# Config containerd
sudo systemctl enable --now containerd.service

# Configure kubelet to use containerd.
sudo mkdir -p  /etc/systemd/system/kubelet.service.d/
cat << EOF | sudo tee  /etc/systemd/system/kubelet.service.d/0-containerd.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
EOF

# Configure kubelet to use systemd as the cgroup driver.
sudo mkdir -p /etc/systemd/system/kubelet.service.d/
cat << EOF | sudo tee  /etc/systemd/system/kubelet.service.d/10-cgroup-driver.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--cgroup-driver=systemd"
EOF

# Reload the systemd manager configuration.
sudo systemctl daemon-reload

# Flush iptables
sudo iptables -L -v
sudo iptables -F
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo systemctl disable netfilter-persistent
sudo systemctl stop netfilter-persistent

## Install cni plugins
mkdir -p /opt/cni/bin
curl -O -L https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-arm-v1.4.0.tgz
sudo tar -C /opt/cni/bin -xzf cni-plugins-linux-arm-v1.4.0.tgz

## Init master nnode
sudo kubeadm init --apiserver-advertise-address=<ip-of-master-node> --cri-socket=/run/containerd/containerd.sock --pod-network-cidr=10.244.0.0/16

## apply kube-flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

## apply kube-state-metrics for metrics
git clone https://github.com/kubernetes/kube-state-metrics?tab=readme-ov-file#kubernetes-deployment
kubectl apply -f kube-state-metrics/examples/standard
sudo rm -rf kube-state-metrics

## Install helm
sudo snap install helm --classic

## Kube promethues stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack --create-namespace --namespace kube-prometheus-stack prometheus-community/kube-prometheus-stack
kubectl -n kube-prometheus-stack get pods

# Apply metallb-native
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml

# Config for metallb-native
sudo cat << EOF | sudo tee -a metallb.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.0.0.40-10.0.0.60 # Range of IP addresses -- For this work need liberate the range in router for TCP and UDP or another protocol in use
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
EOF
sudo kubectl apply -f metallb.yaml

# Install ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

# Config nginx proxy reverse
sudo cat << EOF | sudo tee -a /etc/nginx/conf.d/ingress.conf
server {
    listen 443 ssl;
    server_name example.com;
    ssl_certificate /etc/ssl/certs/tls.crt;
    ssl_certificate_key /etc/ssl/private/tls.key;
    ssl_session_cache builtin:1000 shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4;
    ssl_prefer_server_ciphers on;
    location / {
        proxy_pass http://ingress;
        proxy_set_header Host $host;
        proxy_set_header X-Scheme $scheme;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

# Config the /etc/hosts
sudo cat << EOF | sudo tee -a /etc/hosts
ip-service-loadbalancer ingress
EOF

# Install nfs-kernel-server (only the NFS server)
sudo apt update
sudo apt install nfs-kernel-server

# Only for master and worker nodes
#sudo apt update
#sudo apt install nfs-common

# Create a directory for the NFS share (only the NFS server)
sudo mkdir /var/nfs/general -p
ls -la /var/nfs/general
sudo chown nobody:nogroup /var/nfs/general

# config exports file
sudo cat << EOF | sudo tee -a /etc/exports 
/var/nfs/general    <ip-of-master-node>(rw,sync,no_subtree_check)
/var/nfs/general    <ip-of-worker-node>(rw,sync,no_subtree_check)
/var/nfs/general    <ip-of-worker-node>(rw,sync,no_subtree_check)
EOF

# Restart the NFS server
sudo systemctl restart nfs-kernel-server

# If have Allow in ufw
#sudo ufw allow from <ip-of-master-node> to any port nfs
#sudo ufw allow from <ip-of-worker-node> to any port nfs

# (On master node) folder /var/nfs/general should be mounted
sudo mkdir -p /nfs/general
sudo mount <nfs-server-ip>:/var/nfs/general /nfs/general
df -h
sudo touch /nfs/general/general.test
ls -l /nfs/general/general.test

# Open file /etc/fstab and add the following line
sudo cat << EOF | sudo tee -a /etc/fstab
<nfs-server-ip>:/var/nfs/general    /nfs/general   nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
EOF

# Install nfs-client-provisioner
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-extern
al-provisioner --set nfs.server=<ip-of-master-node> --set nfs.path=/var/nfs/general --set storageClass.name=nfs

kubeadm token create --print-join-command

# reboot the system to apply nfs-server and client
sudo reboot -f
