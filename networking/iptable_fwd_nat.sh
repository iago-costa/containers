
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     udp  --  virbr0 any     anywhere             anywhere             udp dpt:domain

# Convert to command in iptables
sudo iptables -A TESTE -i virbr0 -o any -p udp -m udp --dport 53 -j ACCEPT

# Add chain TESTE
sudo iptables -N TESTE

 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     all  --  enp1s0 virbr0  anywhere             192.168.100.0/24     ctstate RELATED,ESTABLISHED

# Convert to command in iptables
sudo iptables -A TESTE -i enp1s0 -o virbr0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT --destination 192.168.100.0/24 --source anywhere
