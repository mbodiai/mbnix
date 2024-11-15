#!/bin/bash

set -e  # Exit on error

# Define paths
NIX_INSTALLER_URL="https://nixos.org/nix/install"
NIX_DAEMON_SERVICE="/etc/systemd/system/nix-daemon.service"

# Step 1: Stop and Remove Existing Nix Daemon
if systemctl is-active --quiet nix-daemon.service; then
    echo "Stopping existing Nix daemon..."
    sudo systemctl stop nix-daemon.service
fi

# Step 2: Remove Old Nix Files and Directories
echo "Removing old Nix files and directories..."
sudo rm -rf /nix /etc/nix /etc/profile.d/nix.sh /etc/systemd/system/nix-daemon.* ~/.nix-profile ~/.nix-defexpr ~/.nix-channels ~/.config/nix

# Step 3: Remove Nix Users and Groups
echo "Removing Nix build users and groups if they exist..."
if getent group nix-build > /dev/null; then
    sudo groupdel nix-build
fi

for i in {1..40}; do
    if id "nixbld$i" &>/dev/null; then
        sudo userdel "nixbld$i"
    fi
done

# Step 4: Clean Up Shell Profile Files
echo "Cleaning up shell profile files..."
for file in /etc/bashrc /etc/zshrc /etc/bash.bashrc; do
    if [ -e "$file.backup-before-nix" ]; then
        sudo mv "$file.backup-before-nix" "$file"
    fi
done

# Step 5: Create /nix Directory
echo "Creating /nix directory..."
sudo mkdir -m 0755 /nix
sudo chown root /nix

# Step 6: Download and Run the Nix Multi-User Installer
echo "Downloading and installing Nix in multi-user mode..."
sh <(curl -L $NIX_INSTALLER_URL) --daemon

# Step 7: Enable and Start the Nix Daemon
echo "Enabling and starting the Nix daemon..."
sudo systemctl daemon-reload
sudo systemctl enable nix-daemon
sudo systemctl start nix-daemon

# Step 8: Add Nix Configuration to Shell Profiles
echo "Adding Nix configuration to shell profiles..."
echo "if [ -e /etc/profile.d/nix.sh ]; then . /etc/profile.d/nix.sh; fi" | sudo tee -a /etc/bash.bashrc /etc/bashrc /etc/zshrc > /dev/null

echo "Nix multi-user installation complete and configured successfully!"

