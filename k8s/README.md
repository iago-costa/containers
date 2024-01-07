
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
You can now join any number of machines by running the following on each node
as root:

kubeadm join <control-plane-host>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>

### kubeadm start/join
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.0.130:6443 --token 0a7eo3.zbird8xnknlrcf82 \
        --discovery-token-ca-cert-hash sha256:e1f54d33b3b57423dc830d1b406dfc9804a1d9c70b376cd5b0ae722f68190df9

cat $HOME/.kube/config

```bash
kubeadm token create --print-join-command
```

### Check pods system
kubectl get pods -n kube-system

### Config Container Network Interface (CNI)
1. Up to date flannel cni config 
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

mkdir -p /opt/cni/bin
curl -O -L https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz
tar -C /opt/cni/bin -xzf cni-plugins-linux-amd64-v1.2.0.tgz

2. Calico cni config
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml

watch kubectl get pods -n calico-system
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl get nodes,po,svc -o wide

2-1. Delete calico config
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml

3. Outdated weave cni config
kubectl apply -f "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s-1.11.yaml"
kubectl delete -f "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s-1.11.yaml"



### Logs kubelet
```bash
journalctl -u kubelet
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
