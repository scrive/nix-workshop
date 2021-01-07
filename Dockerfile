FROM ubuntu:20.04

ARG UID=1000
ARG GID=1000

RUN groupadd -g $GID -o user && \
  useradd -m -u $UID -g $GID -o -s /bin/bash user && \
  usermod -aG sudo user && \
  DEBIAN_FRONTEND="noninteractive" apt-get update && \
  apt-get install -y git curl wget sudo xz-utils && \
  echo "user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user

ENV USER user
USER user

WORKDIR /home/user

COPY --chown=user:user ./nix.conf /home/user/.config/nix/nix.conf

RUN curl -L https://nixos.org/nix/install | sh

RUN . /home/user/.nix-profile/etc/profile.d/nix.sh && \
  nix-channel --add https://nixos.org/channels/nixos-20.09 nixpkgs && \
  nix-channel --update && \
  nix-env -i cachix
