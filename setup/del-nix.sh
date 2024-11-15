#!/bin/bash

# Stop Nix service if it exists
if systemctl is-active --quiet nix-daemon.service; then
    sudo systemctl stop nix-daemon.service
fi

# Remove Nix directories
sudo rm -rf /nix
sudo rm -rf /etc/nix
sudo rm -rf /etc/profile.d/nix.sh
sudo rm -rf /etc/systemd/system/nix-daemon.service
sudo rm -rf /etc/systemd/system/nix-daemon.socket

# Unset environment variables
unset NIX_USER_PROFILE_DIR
unset NIX_PATH

# Remove Nix build group if it exists
if getent group nix-build >/dev/null; then
    sudo groupdel nix-build
fi

# Remove Nix build users if they exist
for i in {1..40}; do
    if id "nixbld$i" &>/dev/null; then
        sudo userdel "nixbld$i"
    fi
done

# Attempt to remove any remaining 'nixbld' group if it exists
if getent group nixbld >/dev/null; then
    sudo groupdel nixbld
fi