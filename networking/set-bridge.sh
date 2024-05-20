# set bridge for device ask the name
default_device_name="enp1s0"
device_name=""
default_bridge_name="virbr0"
bridge_name=""

# echo the links
echo "Links:"
sudo ip link show | grep "^[0-9]" | awk '{print $2}' | sed 's/://g'

while [ -z $bridge_name ]; do
    echo -n "Enter the bridge name (default: $default_bridge_name): "
    read bridge_name
    if [ -z $bridge_name ]; then
        bridge_name=$default_bridge_name
    fi
done

# if bridge name is not exist create it
if [ -z $(sudo ip link show | grep $bridge_name) ]; then
  echo "Bridge $bridge_name is not exist, creating..."
  sudo ip link add name $bridge_name type bridge
  sudo ip link set $bridge_name up
fi

while [ -z $device_name ]; do
    echo -n "Enter the device name (default: $default_device_name): "
    read device_name
    if [ -z $device_name ]; then
        device_name=$default_device_name
    fi
done

# delete the ip address of the bridge
#sudo ip addr flush dev $bridge_name

sudo ip addr del 192.168.122.1/24 dev $bridge_name

# set the device to the bridge
sudo ip link set $device_name master $bridge_name

# up the bridge
sudo ip link set $bridge_name up

# set ip to bridge in same network
sudo ip addr add 192.168.0.125/24 dev virbr0

sudo ip link set $device_name nomaster

sudo ip link set $device_name master $bridge_name

# show the bridge
sudo ip addr show

