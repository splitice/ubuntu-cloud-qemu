FROM ubuntu:latest

COPY scripts /scripts
COPY setup /setup

RUN apt-get update && \
    bash scripts/prepare-qemu.sh