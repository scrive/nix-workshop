#!/usr/bin/env bash

set -euxo pipefail

docker build \
  --tag nix-workshop \
  --build-arg UID=$(id -u) \
  --build-arg GID=$(id -g) \
  .

docker run --rm -it \
  -v "$(pwd):/home/user/nix-workshop" \
  nix-workshop \
  /bin/bash --login
