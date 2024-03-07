
## Monitoring the PID
strace -o output.txt -s 256 -r -f -p ${PID}

## Write in, out and err from PID
echo "shows on the tty but bypasses cat" > /proc/${PID}/fd/${STD}

## Copy in: 0, out: 1, err: 2 from PID
cat /proc/${PID}/fd/${STD} > ${PID}-${STD}.log
