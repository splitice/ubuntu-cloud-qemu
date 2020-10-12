FROM ubuntu:latest

COPY scripts /scripts
COPY setup /setup

RUN apt-get update && \
    bash setup/prepare-qemu.sh

ENTRYPOINT ["/bin/bash", "/scripts/entrypoint.sh"]