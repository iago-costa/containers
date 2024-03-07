#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
echo "Starting QEMU"
echo "file QCow2: $1"
echo "bridge: $2"
echo "tap: $3"

IMAGE="$1"
BRIDGE="$2"
TAP="$3"
# RAND_MAC=$(printf 'DE:AD:BE:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)))
#
# get the last character of the tap name
TAP_LAST_CHAR=${TAP: -1}
RAND_MAC=$(printf 'DE:AD:BE:EF:%02X:%02X\n' $TAP_LAST_CHAR $TAP_LAST_CHAR)


# verify IMAGE is empty using variable
if [ -z "$IMAGE" ]; then
    echo "QCow2 file not specified"
    exit 1
fi

if [ -z "$BRIDGE" ]; then
    echo "Bridge not specified"
    exit 1
fi

if [ -z "$TAP" ]; then
    echo "Tap file not specified"
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
    -device virtio-net-pci,netdev=${BRIDGE},mac=${RAND_MAC} \
    -netdev tap,id=${BRIDGE},ifname=${TAP},script=no,downscript=no,vhost=on \
    -debugcon file:${IMAGE}.log \
    ${IMAGE}
