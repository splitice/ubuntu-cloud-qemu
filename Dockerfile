FROM debian:stretch-slim

COPY prepare.sh /run/

RUN apt-get update && apt-get -y upgrade && \
    apt-get --no-install-recommends -y install \
        iproute2 \
        jq \
        python3 \
        udhcpd \
    && bash /run/prepare.sh \
    && apt-get clean

COPY qemu-ifdown /run/
COPY qemu-ifup /run/
COPY run.sh /run/

ENTRYPOINT ["/run/run.sh"]

# Mostly users will probably want to configure memory usage.
CMD ["-m", "512M"]
