#!/bin/sh

set -e

apt update
apt install -y \
  openssh-client \
  make \
  libssl-dev \
  lldpad \
  iproute2 \
  bridge-utils \
  tcpdump \
  iputils-ping \
  ncat \
  jq \
  curl \
  python3 \
  pipx

pipx install pipx
pipx install jinja2-cli

apt purge --autoremove pipx

pipx ensurepath
