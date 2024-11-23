#!/bin/sh
nix-env --list-generations
nix-env --delete-generations old
nix-collect-garbage
sudo find /nix/store -name nix