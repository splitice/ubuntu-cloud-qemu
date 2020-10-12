FROM debian:buster-20190228-slim

COPY prepare.sh /run/

RUN apt-get update && apt-get -y upgrade && \
    apt-get --no-install-recommends -y install \
        iproute2 \
        jq \
        python3 \
        qemu-system-x86 \
        udhcpd \
    && bash /run/prepare.sh \
    && apt-get clean

COPY generate-dhcpd-conf /run/
COPY qemu-ifdown /run/
COPY qemu-ifup /run/
COPY run.sh /run/

ENTRYPOINT ["/run/run.sh"]

# Mostly users will probably want to configure memory usage.
CMD ["-m", "1G"]
