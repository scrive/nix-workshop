#!/usr/bin/env bash

plan=$(nix-build -j4 --no-out-link --arg useMaterialization false -A plan-nix project.nix)

rm -rf plan

cp -r $plan plan

find plan -type d -exec chmod 755 {} \;

nix-hash --base32 --type sha256 plan > plan-hash.txt
