# Copyright (c) 2024 Intel Corporation
# SPDX-License-Identifier: Apache 2.0

# NOTE: To build this you will need a docker version >= 19.03 and DOCKER_BUILDKIT=1
#
#       If you do not use buildkit you are not going to have a good time
#
#       For reference:
#           https://docs.docker.com/develop/develop-images/build_enhancements/

ARG UBUNTU_VERSION=22.04

FROM ubuntu:${UBUNTU_VERSION}

# See http://bugs.python.org/issue19846
ENV LANG=C.UTF-8

RUN if [ -f /etc/apt/apt.conf.d/proxy.conf ]; then rm /etc/apt/apt.conf.d/proxy.conf; fi && \
    if [ ! -z ${HTTP_PROXY} ]; then echo "Acquire::http::Proxy \"${HTTP_PROXY}\";" >> /etc/apt/apt.conf.d/proxy.conf; fi && \
    if [ ! -z ${HTTPS_PROXY} ]; then echo "Acquire::https::Proxy \"${HTTPS_PROXY}\";" >> /etc/apt/apt.conf.d/proxy.conf; fi
RUN apt update -y && \
    apt full-upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    google-perftools \
    openssh-server \
    net-tools
RUN apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    if [ -f /etc/apt/apt.conf.d/proxy.conf ]; then rm /etc/apt/apt.conf.d/proxy.conf; fi
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 100

WORKDIR /root

ARG IPEX_VERSION=2.6.0
ARG TORCHCCL_VERSION=2.6.0
ARG PYTORCH_VERSION=2.6.0
ARG TORCHAUDIO_VERSION=2.6.0
ARG TORCHVISION_VERSION=0.21.0
RUN python -m venv venv && \
    . ./venv/bin/activate && \
    python -m pip --no-cache-dir install --upgrade \
    pip \
    setuptools \
    psutil && \
    python -m pip install --no-cache-dir \
    torch==${PYTORCH_VERSION}+cpu torchvision==${TORCHVISION_VERSION}+cpu torchaudio==${TORCHAUDIO_VERSION}+cpu --index-url https://download.pytorch.org/whl/cpu && \
    python -m pip install --no-cache-dir \
    intel_extension_for_pytorch==${IPEX_VERSION} oneccl_bind_pt==${TORCHCCL_VERSION} --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/cpu/us/ && \
    python -m pip install intel-openmp && \
    python -m pip cache purge

