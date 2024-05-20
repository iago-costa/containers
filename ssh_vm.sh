cat << EOF | sudo tee /etc/ssh/sshd_config
Port 22
PasswordAuthentication no
AllowAgentForwarding yes
ChallengeResponseAuthentication no
EOF

cat << EOF | sudo tee $HOME/.ssh/authorized_keys
<public-key>
EOF

sudo vim /usr/lib/systemd/system/sshd.service

sudo systemctl daemon-reload
sudo systemctl restart sshd
sudo systemctl status sshd
sudo systemctl enable sshd
