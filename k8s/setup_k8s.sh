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

## Install cni plugins
mkdir -p /opt/cni/bin
curl -O -L https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz
sudo tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-v1.4.0.tgz

mkdir -p /opt/cni/bin
curl -O -L https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-arm-v1.4.0.tgz
sudo tar -C /opt/cni/bin -xzf cni-plugins-linux-arm-v1.4.0.tgz


