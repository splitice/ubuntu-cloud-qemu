FROM debian:buster-20190228-slim

COPY prepare.sh /run/

RUN printf "deb http://httpredir.debian.org/debian buster-backports main non-free\ndeb-src http://httpredir.debian.org/debian buster-backports main non-free" > /etc/apt/sources.list.d/backports.list

RUN apt-get update && apt-get -y upgrade && \
    apt-get --no-install-recommends -y install \
        iproute2 \
        jq \
        python3 \
        udhcpd \
    && apt-get --no-install-recommends -y --fix-broken -t buster-backports install "qemu-system-x86" \
    && bash /run/prepare.sh \
    && apt-get clean

COPY qemu-ifdown /run/
COPY qemu-ifup /run/
COPY run.sh /run/

ENTRYPOINT ["/run/run.sh"]

# Mostly users will probably want to configure memory usage.
CMD ["-m", "512M"]
