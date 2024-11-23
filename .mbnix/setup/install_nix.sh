#!/bin/bash

set -e  # Exit on error

# Define paths
NIX_INSTALLER_URL="https://nixos.org/nix/install"

# Step 1: Stop and Remove Existing Nix Daemon
if systemctl is-active --quiet nix-daemon.service; then
    echo "Stopping existing Nix daemon..."
    sudo systemctl stop nix-daemon.service
fi

# Step 2: Remove Old Nix Files and Directories
echo "Removing old Nix files and directories..."
sudo rm -rf /nix /etc/nix /etc/profile.d/nix.sh /etc/systemd/system/nix-daemon.* ~/.nix-profile ~/.nix-defexpr ~/.nix-channels ~/.config/nix


# Step 3: Download and Install Nix in Multi-User Mode
echo "Downloading and installing Nix in multi-user mode..."
sh <(curl -L "$NIX_INSTALLER_URL") --daemon

