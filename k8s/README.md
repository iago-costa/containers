
## Init k8s
```bash
sudo kubeadm init \
--apiserver-advertise-address=<ip> \
--cri-socket=/run/containerd/containerd.sock \
--pod-network-cidr 10.244.0.0/16

sudo kubeadm init \
--apiserver-advertise-address=10.0.0.212 \
--cri-socket=/run/containerd/containerd.sock \
--pod-network-cidr=10.244.0.0/16

```

## Reset k8s
```bash
sudo kubeadm reset -f || true
rm -rf $HOME/.kube/config || true
rm -rf /etc/cni/net.d || true
```

## Setup k8s
(k8s-setup)[https://www.clearlinux.org/clear-linux-documentation/tutorials/kubernetes.html]

### Choose the Container Runtime Interface
1. CRI+O
2. containerd
3. Docker

### Add nodes
```bash
You can now join any number of machines by running the following on each node
as root:

kubeadm join <control-plane-host>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

### kubeadm start/join

```bash
# Your Kubernetes control-plane has initialized successfully!

# To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

#You should now deploy a pod network to the cluster.
#Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
#  https://kubernetes.io/docs/concepts/cluster-administration/addons/

# Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.0.130:6443 --token 0a7eo3.zbird8xnknlrcf82 \
        --discovery-token-ca-cert-hash sha256:e1f54d33b3b57423dc830d1b406dfc9804a1d9c70b376cd5b0ae722f68190df9

cat $HOME/.kube/config
```

```bash
kubeadm token create --print-join-command
```

### Check pods system
kubectl get pods -n kube-system

### Config Container Network Interface (CNI)
1. Up to date flannel cni config
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.
yml

mkdir -p /opt/cni/bin
curl -O -L https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz
tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-v1.2.0.tgz

```

2. Calico cni config
```bash
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml

watch kubectl get pods -n calico-system
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl get nodes,po,svc -o wide
```
2-1. Delete calico config
```bash
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml
```
3. Outdated weave cni config
```bash
kubectl apply -f "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s-1.11.yaml"
kubectl delete -f "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s-1.11.yaml"
```

### Logs kubelet
```bash
journalctl -u kubelet
```

### Disable iptables in all nodes
```bash
sudo iptables -L -v
sudo iptables -F
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo systemctl disable netfilter-persistent
sudo systemctl stop netfilter-persistent
```

## Copy kube config to local
```bash
scp -O master-oracle-k8s-no-dns:/root/.kube/config "config"
#copy file config to clipboard using xclip
cat config | xclip -selection clipboard
```

## Run nginx aand expose port 3000 3 replicas
```bash
kubectl run nginx --image=nginx --port=3000 --expose 3000
kubectl expose deployment nginx --type=NodePort
kubectl get node,po,svc -A -o wide
# delete service and deployment
kubectl delete svc nginx
kubectl delete deployment nginx
```

## Run ServiceAccount and RBAC
```bash
kubectl apply -f sa.yaml
kubectl apply -f rbac.yaml
kubectl get sa,role,rolebinding -A -o wide
kubectl delete -f sa.yaml
kubectl delete -f rbac.yaml
```

## Kube proxy
```bash
kubectl proxy --address 0.0.0.0 --accept-hosts '.*' --port=30725
```

## Prometheus
```bash
git clone https://github.com/techiescamp/kubernetes-prometheus
kubectl create namespace monitoring
kubectl create -f clusterRole.yaml
kubectl create -f config-map.yaml
kubectl create -f prometheus-deployment.yaml
kubectl get deployments --namespace=monitoring
# https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/
```

## Prometheus Stack
```bash
# https://opensource.com/article/20/6/kubernetes-lens
# https://github.com/digitalocean/Kubernetes-Starter-Kit-Developers/blob/main/04-setup-observability/prometheus-stack.md#step-1---installing-the-prometheus-stack
git clone 
```

## Kube state metrics
```bash
git clone https://github.com/kubernetes/kube-state-metrics?tab=readme-ov-file#kubernetes-deployment
kubectl apply -f kube-state-metrics/examples/standard
kubectl get pods -n kube-system
```

## CoreDNS No route to host
```bash
# verify iptables
iptables -L
iptables -S
# clean block iptables
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
```

## Service troubleshooting
```bash
# Intermittent connection refused errors
# Verify the labels on the pod and service selectors match
kubectl get pods --show-labels
kubectl get svc --show-labels
# Verify the selectors match from svc and labels from pods
kubectl describe svc <service-name>
kubectl describe pod <pod-name>
# Verify the endpoints are populated
kubectl get endpoints <service-name>
# Verify the pod is running
kubectl get pods
# Verify the service is running
kubectl get svc
# Verify the service is reachable from the node
curl http://<node-ip>:<node-port>
# Verify the service is reachable from another pod
kubectl run -it --rm --restart=Never busybox --image=busybox sh
wget -qO- http://<service-name>:<service-port>
# Verify the service is reachable from outside the cluster
kubectl run -it --rm --restart=Never busybox --image=busybox sh
wget -qO- http://<node-ip>:<node-port>
# Verify the service is reachable from inside the cluster
kubectl run -it --rm --restart=Never busybox --image=busybox sh
wget -qO- http://<service-name>:<service-port>
# Verify the service is reachable from the cluster network
kubectl run -it --rm --restart=Never busybox --image=busybox sh
wget -qO- http://<service-name>.<namespace-name>.svc.cluster.local:<service-port>
# Verify the service is reachable from the cluster DNS
kubectl run -it --rm --restart=Never busybox --image=busybox sh
wget -qO- http://<service-name>.<namespace-name>.svc.cluster.local:<service-port>
```

## Helm install
```bash
# https://helm.sh/docs/intro/install/
# https://helm.sh/docs/intro/quickstart/
sudo snap install helm --classic
```

### Install kube-prometheus-stack
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack \
  --create-namespace \
  --namespace kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack
kubectl -n kube-prometheus-stack get pods
kubectl port-forward --address 10.0.0.212 -n kube-prometheus-stack svc/kube-prometheus-stack-prometheus 32000:9090
```

## Config nfs-client-provisioner
```bash
# https://medium.com/@shatoddruh/kubernetes-how-to-install-the-nfs-server-and-nfs-dynamic-provisioning-on-azure-virtual-machines-e85f918c7f4b

# Install nfs-kernel-server (only the NFS server)
sudo apt update
sudo apt install nfs-kernel-server

# Only for master and worker nodes
sudo apt update
sudo apt install nfs-common

# Create a directory for the NFS share (only the NFS server)
sudo mkdir /var/nfs/general -p
ls -la /var/nfs/general
sudo chown nobody:nogroup /var/nfs/general

# config exports file
sudo vim /etc/exports
# /var/nfs/general    <ip-of-master-node>(rw,sync,no_subtree_check)
# /var/nfs/general    <ip-of-worker-node>(rw,sync,no_subtree_check)

# Restart the NFS server
sudo systemctl restart nfs-kernel-server

# Allow in ufw
sudo ufw allow from <ip-of-master-node> to any port nfs
sudo ufw allow from <ip-of-worker-node> to any port nfs

# (On master node) folder /var/nfs/general should be mounted
sudo mkdir -p /nfs/general
sudo mount <nfs-server-ip>:/var/nfs/general /nfs/general
df -h
sudo touch /nfs/general/general.test
ls -l /nfs/general/general.test

# Open file /etc/fstab and add the following line
sudo vim /etc/fstab
<nfs-server-ip>:/var/nfs/general    /nfs/general   nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0

# Save and exit the file and reboot the system
sudo reboot -f

# Install nfs-client-provisioner
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-extern
al-provisioner \
    --set nfs.server=10.0.0.212 \
    --set nfs.path=/var/nfs/general \
    --set storageClass.name=nfs
```

### Config ssl-tls cert and key
```bash
## Command to create the secret
kubectl create secret tls ingress-cert --namespace dev --key=certs/ingress-tls.key --cert=certs/ingress-tls.crt
```

### Example config ingress
```yaml
# example: https://snyk.io/blog/setting-up-ssl-tls-for-kubernetes-ingress/
```

## Config metallb for LoadBalancer and Ingress
```bash
kubectl create ns metallb-system
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
kubectl delete -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
```

### Trouble shooting metallb
```bash
kubectl delete -A ValidatingWebhookConfiguration metallb-webhook-configuration
```

### Config metallb.yaml
```yaml
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

```

## Config purelb for LoadBalancer and Ingress
```bash
helm repo add purelb https://gitlab.com/api/v4/projects/20400619/packages/helm/stable
helm repo update
helm install --create-namespace --namespace=purelb purelb purelb/purelb

helm uninstall --namespace=purelb purelb

# To install the by manifest
kubectl create ns purelb
kubectl apply -f https://gitlab.com/api/v4/projects/purelb%2Fpurelb/packages/generic/manifest/0.0.1/purelb-complete.yaml

# To uninstall the chart
kubectl delete ns purelb
kubectl delete -f https://gitlab.com/api/v4/projects/purelb%2Fpurelb/packages/generic/manifest/0.0.1/purelb-complete.yaml
```

## Config ingress-nginx-controller
```bash
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

helm uninstall --namespace=ingress-nginx ingress-nginx

# How delete namespace and all resources
kubectl create ns ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

kubectl delete ns ingress-nginx
kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/baremetal/deploy.yaml

kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml

```

## Trouble shooting nginx controller
```bash
kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
```

## Links purelb and ingress-nginx-controller
```bash
https://kubernetes.github.io/ingress-nginx/deploy/
https://kubernetes.github.io/ingress-nginx/deploy/baremetal/
https://purelb.gitlab.io/docs/operation/services/
```

### Config in /etc/hosts for ingress-nginx work
```bash
ip-service-loadbalancer ingress
```

### Proxy reverse with nginx
```bash
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
```

#### Move for folder
```bash
sudo mv ingress.conf /etc/nginx/conf.d/
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
sudo systemctl reload nginx
sudo systemctl stop nginx
sudo systemctl disable nginx
```

### Logs ingress-nginx-controller
```bash
kubectl logs --timestamps -n ingress-nginx ingress-nginx-controller-7dcdbcff84-dp8qf
```

### Links metallb and ingress-nginx-controller
```bash
https://kubernetes.github.io/ingress-nginx/deploy/baremetal/
https://metallb.universe.tf/installation/
https://www.reddit.com/r/kubernetes/comments/xkx0fo/kubernetes_on_baremetal_with_metallb/
https://metallb.universe.tf/concepts/layer2/
https://kubernetes.github.io/ingress-nginx/user-guide/basic-usage/
https://kubernetes.io/docs/concepts/services-networking/ingress/#ingress-class
```

### Observations from this installation
```txt
# Allow in subnet traffic in TCP and UDP protocols
# Install k8s with containerd as CRI
# Install flannel for CNI
# Install kube-state-metrics for see metrics from k8s
# Install prometheus with kube-prometheus-stack for see metrics from k8s
# Install nfs-client-provisioner for dynamic provisioning storage for database
# Install ingress-nginx-controller for incomming traffic from virtual subnet, virtual private net and internet
# Install metallb with provider cloud for loadbalancer incomming traffic from ingress-nginx-controller
# Avoid use tls in ingress-nginx-controller
# Use nginx as reverse proxy for ingress-nginx-controller
```
