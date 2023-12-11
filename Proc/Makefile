
m:
	## Example use: make m p=1234
	## Monitoring the PID
	strace -o ${p}_strace.log -s 512 -r -f -p ${p}

w:
	## Write in, out and err from PID
	## Example use: make w p=1234 s=0
	echo "shows on the tty but bypasses cat" > /proc/${p}/fd/${s}

c:
	#
	## Copy in: 0, out: 1, err: 2 from PID
	## Example use: make c p=1234 s=0
	cat /proc/${p}/fd/${s} > ${p}_${s}.log
i
n:
	## Example use: make n p=1234
	## Network connections
	netstat -p ${p}

node:
	## Example use: make node p=1234
	## Node processes
	ps -ef | grep node
	
s:
	## Example use: make s p=1234
	## Socket connections
	## ss -apn | grep id-socket
	sudo lsof -U -a -p ${p}
