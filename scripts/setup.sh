#!/usr/bin/env bash

CACHIX_STORE=$(cat config/cachix-store)
cachix use $CACHIX_STORE
cachix authtoken $(cat config/cachix-token)
