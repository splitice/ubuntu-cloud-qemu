chmod +x /scripts/*

#curl -sL https://deb.nodesource.com/setup_14.x | bash -

apt-get install -y cloud-image-utils qemu qemu-system net-tools iproute2 ifupdown udhcpd jq openssh-client iputils-ping ansible sshpass tcpdump nano procps python3-pip python-pip nodejs git-core curl build-essential openssl libssl-dev python npm

pip install scapy

# This is already in qcow2 format.
if [ ! -f "/image" ]; then
  wget "https://cloud.debian.org/images/cloud/buster/20200928-407/debian-10-generic-amd64-20200928-407.qcow2" -O /image

  # sparse resize: does not use any extra space, just allows the resize to happen later on.
  # https://superuser.com/questions/1022019/how-to-increase-size-of-an-ubuntu-cloud-image
  qemu-img resize "/image" +12G
fi