
# Tailscale

curl -fsSL https://tailscale.com/install.sh | sh
yay -Sy tailscale-git --debug
sudo systemctl start tailscaled
sudo tailscale up
