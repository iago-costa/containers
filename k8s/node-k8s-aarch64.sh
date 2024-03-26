#!/bin/bash

# Install nfs-client
sudo apt update
sudo apt install nfs-common

# Flush iptables
sudo iptables -L -v
sudo iptables -F
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo systemctl disable netfilter-persistent
sudo systemctl stop netfilter-persistent

# Make join node for cluster
kubeadm join <control-plane-host>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
