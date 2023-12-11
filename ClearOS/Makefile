new:
	# create new qemu vm
	# example usage; make new i=
	sh qemu_install.sh ${i}.qcow2 clear-40370-live-server.iso mynet0 tap999;
r1:
	# run qemu vm master
	sh qemu_start.sh master.cow mynet0 tap0;

r2:
	# run qemu vm slave
	sh qemu_start.sh worker1.cow mynet0 tap1;

r3:
	# run qemu vm slave
	sh qemu_start.sh worker2.cow mynet0 tap2;

shownet:
	# show network
	# example usage; make shownet d=eno1
	sudo ip address show ${d}
	sudo ip route show dev ${d}

newnet:
	# create network bridge
	# example usage; make newnet b=mynet0
ifndef b
	$(eval b := "mynet0")
endif
	sudo ip link set ${b} down || true
	sudo ip link delete ${b} type bridge || true
	sudo ip link add ${b} type bridge
	sudo ip link set ${b} up

delnet:
	# example usage; make delnet d=eno1 a=192.168.0.123/24 r=192.168.0.0/24
ifndef a
	$(error a is not set)
endif
ifndef r
	$(error r is not set)
endif
	sudo ip addr del ${a} dev ${d} || true
	sudo ip route delete ${r} dev ${d} || true
	sudo ip addr flush dev ${d} || true
	sudo ip route flush dev ${d} || true

confnet:
	# create network bridge and add device internet on bridge
	# example usage; make confnet b=mynet0 d=eno1 g=192.168.0.1 a=192.168.0.123/24 r=192.168.0.0/24
	# Summary:
	# b = bridge name
	# d = device name
	# g = gateway address
	# a = ip address
	# r = route address
ifndef b # b is from bridge name
	$(eval b := "mynet0")
endif
ifndef d # d is from device name
	$(eval d := "eno1")
endif
ifndef g # g is from gateway address
	$(eval g := "192.168.0.1")
endif
ifndef a
	# $(eval a := $(shell sudo ip addr show dev ${b} | grep -w inet | awk '{print $2}' ))
	$(eval a := "192.168.0.123/24")
endif
ifndef r # r is from route address
	$(eval r := "192.168.0.0/24")
endif
ifndef gm # gm is from gateway with mask
	$(eval gm := "192.168.0.1/24")
endif
	make newnet b=${b}
	make shownet d=${d}
	sudo ip address add ${a} dev ${b}
	sudo ip route append default via ${g} dev ${b}
	sudo ip link set ${d} master ${b}
	make delnet d=${d} a=${a} r=${r}
	sudo iptables -I FORWARD -m physdev --physdev-is-bridged -j ACCEPT
	make stats b=${b} a=${gm}
	make tap b=${b} t=tap0
	make tap b=${b} t=tap1
	make tap b=${b} t=tap2

tap:
	# create network bridge
	# example usage; make tap b=mynet0 t=tap0
ifndef b
	$(eval b := "mynet0")
endif
ifndef t
	$(error t is not set)
endif
	sudo ip link delete ${t} type tap || true
	sudo ip tuntap add dev ${t} mode tap
	sudo ip link set dev ${t} master ${b}
	sudo ip link set dev ${b} up || true
	sudo ip link set up dev ${t}

stats:
	# show network stats
	# example usage; make stats b=mynet0 gm=192.168.0.1/24
ifndef b
	$(eval b := "mynet0")
endif
ifndef gm
	$(eval gm := "192.168.0.1/24")
endif
	sudo iptables --list
	sudo brctl showmacs ${b} || true
	nmap -sn ${gm} || true
	
