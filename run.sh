#!/usr/bin/env bash

user_data=user-data.img
if [ ! -f "$user_data" ]; then
  # For the password.
  # https://stackoverflow.com/questions/29137679/login-credentials-of-ubuntu-cloud-server-image/53373376#53373376
  # https://serverfault.com/questions/920117/how-do-i-set-a-password-on-an-ubuntu-cloud-image/940686#940686
  # https://askubuntu.com/questions/507345/how-to-set-a-password-for-ubuntu-cloud-images-ie-not-use-ssh/1094189#1094189
  cat >user-data <<EOF
#cloud-config
password: asdfqwer
chpasswd: { expire: False }
ssh_pwauth: True
EOF

cat <<- EOF > network-config-v2.yaml
version: 2
ethernets:
    ens3:
        dhcp4: false
        dhcp6: false
        addresses:
          - {VMIP}/24
        gateway4: 172.17.0.1
        nameservers:
          addresses:
            - 8.8.8.8
            - 8.8.4.4
EOF
  cloud-localds --network-config=network-config-v2.yaml "$user_data" user-data
fi


# A bridge of this name will be created to host the TAP interface created for
# the VM
QEMU_BRIDGE='qemubr0'

# DHCPD must have an IP address to run, but that address doesn't have to
# be valid. This is the dummy address dhcpd is configured to use.
DUMMY_DHCPD_IP='10.0.0.1'

# These scripts configure/deconfigure the VM interface on the bridge.
QEMU_IFUP='/run/qemu-ifup'
QEMU_IFDOWN='/run/qemu-ifdown'

function default_intf() {
    ip -json route show |
        jq -r '.[] | select(.dst == "default") | .dev'
}

our_ip=$(ip addr show dev eth0 | grep inet | awk '{print $2}' |  head -n1)
route_ip=$(ip route | grep default | head -n1 | awk '{print $3}')

echo "Route $our_ip -> $route_ip"

# First step, we run the things that need to happen before we start mucking
# with the interfaces. We start by generating the DHCPD config file based
# on our current address/routes. We "steal" the container's IP, and lease
# it to the VM once it starts up.
default_dev=`default_intf`

# Now we start modifying the networking configuration. First we clear out
# the IP address of the default device (will also have the side-effect of
# removing the default route)
ip route
ip addr flush dev $default_dev

# Next, we create our bridge, and add our container interface to it.
ip link add $QEMU_BRIDGE type bridge
ip link set dev $default_dev master $QEMU_BRIDGE

# Then, we toggle the interface and the bridge to make sure everything is up
# and running.
ip link set dev $default_dev up
ip link set dev $QEMU_BRIDGE up


ip addr
ip route 

ip addr add $our_ip dev qemubr0
ip route add default via $route_ip dev qemubr0

if [[ -e /dev/kvm ]]; then
    additional="-enable-kvm -cpu host"
fi

# And run the VM! A brief explaination of the options here:
# -enable-kvm: Use KVM for this VM (much faster for our case).
# -nographic: disable SDL graphics.
# -serial mon:stdio: use "monitored stdio" as our serial output.
# -nic: Use a TAP interface with our custom up/down scripts.
# -drive: The VM image we're booting.
exec qemu-system-x86_64 -nographic -serial mon:stdio \
    -nic tap,id=qemu0,script=$QEMU_IFUP,downscript=$QEMU_IFDOWN \
    "$@" \
    -drive format=qcow2,file=/image \
    -drive "file=${user_data},format=raw" \
    -smp $(nproc) $additional
