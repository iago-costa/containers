#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh

echo "Installing QEMU"
echo "file QCow2: $1"
echo "file ISO: $2"
echo "bridge: $3"
echo "tap: $4"

IMAGE="$1"
ISO="$2"
BRIDGE="$3"
TAP="$4"

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

if [ -z "$TAP" ]; then
    echo "Tap not specified"
    exit 1
fi

# if --help is specified, print help and exit
if [ "$1" == "--help" ]; then
    echo "Usage: $0 <qcow2 file> <iso file> [bridge] [tap]"
    echo "Example: sh $0 worker1.cow clear-40370-live-server.iso mynet0 tap1"
    exit 1
fi

## verify if the image file exists
if [ ! -f "$IMAGE" ]; then
    echo "Image file not found!"
    sudo qemu-img create -f qcow2 ${IMAGE} 20G
    echo "Image file created!"
else
    echo "Image file found!"
    exit 1
fi

sudo qemu-system-x86_64 \
    -enable-kvm \
    -cpu host \
    -m 2048 \
    -cdrom ${ISO} \
    -boot order=d \
    -device virtio-net-pci,netdev=${BRIDGE} \
    -netdev tap,id=${BRIDGE},ifname=${TAP},script=no,downscript=no,vhost=on \
    -drive file=${IMAGE},format=qcow2

