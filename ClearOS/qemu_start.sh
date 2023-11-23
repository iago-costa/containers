#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

echo "Starting QEMU"
echo "file QCow2: $1"
echo "file ISO: $2"
echo "bridge: $3"

IMAGE="$1"
ISO="$2"
BRIDGE="$3"

# verify IMAGE is empty using variable
if [ -z "$IMAGE" ]; then
    echo "QCow2 file not specified"
    exit 1
fi

if [ -z "$ISO" ]; then
    echo "ISO file not specified"
    exit 1
fi

if [ -z "$BRIDGE" ]; then
    echo "Bridge not specified"
    exit 1
fi

# if --help is specified, print help and exit
if [ "$1" == "--help" ]; then
    echo "Usage: $0 <qcow2 file> [bridge] [tap]"
    echo "Example: sh $0 worker1.cow mynet0 tap1"
    exit 1
fi

sudo qemu-system-x86_64 \
    -enable-kvm \
    -smp sockets=1,cpus=4,cores=2 -cpu host \
    -m 2048 \
    -vga none -nographic \
    -device virtio-net-pci,netdev=${BRIDGE} \
    -netdev tap,id=${BRIDGE},ifname=${TAP},script=no,downscript=no,vhost=on \
    -debugcon file:${IMAGE}.log \
    ${IMAGE}
