#!/bin/sh

set -e  # Exit on error
NIX_INSTALLER_URL="https://nixos.org/nix/install"
# Define paths
# Download installer first
curl -L "$NIX_INSTALLER_URL" > /tmp/nix-installer.sh

# Check download was successful
if [ ! -f /tmp/nix-installer.sh ]; then
    echo "Failed to download Nix installer"
    exit 1
fi

# Make executable and run
if [ -f /etc/bash.bashrc.backup-before-nix ]; then
    sudo mv /etc/bash.bashrc /etc/bash.bashrc.backup-before-before-nix
    sudo mv /etc/bash.bashrc.backup-before-nix /etc/bash.bashrc
fi
if [ -f /etc/profile.backup-before-nix ]; then
    sudo mv /etc/profile /etc/profile.backup-before-before-nix
    sudo mv /etc/profile.backup-before-nix /etc/profile
fi
if [ -f /etc/zsh/zshrc.backup-before-nix ]; then
    sudo mv /etc/zsh/zshrc /etc/zsh/zshrc.backup-before-before-nix
    sudo mv /etc/zsh/zshrc.backup-before-nix /etc/zsh/zshrc
fi

chmod +x /tmp/nix-installer.sh
/tmp/nix-installer.sh --daemon

# Cleanup
if [ -f /etc/bash.bashrc.backup-before-before-nix ]; then
    sudo mv /etc/bash.bashrc.backup-before-before-nix /etc/bash.bashrc
fi
if [ -f /etc/profile.backup-before-before-nix ]; then
    sudo mv /etc/profile.backup-before-before-nix /etc/profile
fi
rm -f /tmp/nix-installer.sh