
## Config ubuntu with zsh and oh-my-zsh and powerlevel10k and nvim and zellij

### All in one

```bash
sudo apt-get update
# Install zsh
sudo apt install -y zsh
# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# Install powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
# install make
sudo apt install -y make
# Download my dotfiles
git clone https://github.com/iago-costa/dotfiles.git ~/dotfiles
make pull -C ~/dotfiles
# Install nvim and zellij
sudo snap install nvim --classic
sudo snap install zellij --classic
# Install gcc
sudo apt install -y gcc
sudo apt install -y g++
```

### Install kubectl

```bash
sudo apt-get update
# Install containerd
sudo apt-get install -y containerd
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates curl
# Download the Google Cloud public signing key:
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl kubeadm kubelet
```

### Iptables rules for oracle cloud


```bash
sudo su
vim /etc/iptables/rules.v4
-A INPUT -p tcp -m state --state NEW -m tcp --dport 6443 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 2379:2380 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 10250 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 10259 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 10257 -j ACCEPT
-A INPUT -p tcp -m state --state NEW -m tcp --dport 30000:32767 -j ACCEPT
iptables-restore < /etc/iptables/rules.v4
```
