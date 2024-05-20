## Activate ssh in master node
1. Generate ssh key and set config
```bash
cd $HOME/.ssh/
ssh-keygen -t rsa
ssh-keygen -t ed25519
cat id_rsa.pub | xclip -sel clip
# Set config
nvim config
```
2. Copy pub key to VM
```bash
# Paste the pub key
vim $HOME/.ssh/authorized_keys
# Set config
cat << EOF | sudo tee /etc/ssh/sshd_config
Port 22
PasswordAuthentication no
AllowAgentForwarding yes
ChallengeResponseAuthentication no
EOF
# Enable file config
# Set EnvironmentFile=-/etc/sysconfig/sshd
vim /usr/lib/systemd/system/sshd.service
# Restart sshd
systemctl restart sshd
```

## nmap scan
```bash
sudo nmap -snP 192.168.0.1/24
sudo nmap -p1-65535 -sV -sS -T4 192.168.0.1/24
```

