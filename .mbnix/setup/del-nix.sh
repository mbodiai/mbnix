#!/bin/bash

# Function to prompt for deletion with visual indication
prompt_and_delete() {
    local file="$1"
    local pattern="$2"
    
    # Search for the pattern in the file
    if grep -q "$pattern" "$file"; then
        echo -e "\nFound matching lines in $file:"
        grep -n "$pattern" "$file" | while IFS=: read -r line_num line; do
            echo -e "  $line_num: $line"
        done
        
        echo -e "\nLines marked with '>>>' will be removed:"
        grep -n "$pattern" "$file" | while IFS=: read -r line_num line; do
            echo -e "  >>> $line_num: $line"
        done
        
        echo "Do you want to remove these lines? (yes/no)"
        read -r response
        
        if [[ "$response" == "yes" ]]; then
            grep -n "$pattern" "$file" | while IFS=: read -r line_num _; do
                sudo sed -i "${line_num}d" "$file"
            done
            echo "Lines removed from $file."
        else
            echo "Skipped $file."
        fi
    fi
}


# Stop Nix services if they exist
if systemctl is-active --quiet nix-daemon.service; then
    sudo systemctl stop nix-daemon.service
fi

if systemctl is-enabled --quiet nix-daemon.service; then
    sudo systemctl disable nix-daemon.service
fi

# Remove Nix directories
sudo rm -rf /nix
sudo rm -rf /etc/nix
sudo rm -rf /etc/profile.d/nix.sh
sudo rm -rf /etc/systemd/system/nix-daemon.service
sudo rm -rf /etc/systemd/system/nix-daemon.socket
sudo rm -rf /nix /etc/nix /etc/profile.d/nix.sh /etc/systemd/system/nix-daemon.* ~/.nix-profile ~/.nix-defexpr ~/.nix-channels ~/.config/nix
# Iterate over all user directories
for user_home in /home/*; do
    # Remove user-specific Nix directories
    sudo rm -rf "$user_home/.nix*"
    sudo rm -rf "$user_home/.cache/nix"
    sudo rm -rf "$user_home/.config/nix"
    sudo rm -rf "$user_home/.local/share/nix"

    # Remove .nix-profile symlink if it exists
    if [ -L "$user_home/.nix-profile" ]; then
        sudo rm -rf "$user_home/.nix-profile"
    fi

    # Remove Nix references from user shell config files with confirmation
    for file in "$user_home/.bashrc" "$user_home/.zshrc" "$user_home/.profile" "$user_home/.bash_profile"; do
        if [ -f "$file" ]; then
            prompt_and_delete "$file" "nix"
        fi
    done
done

# Remove Nix references from global shell configurations with confirmation
for file in /etc/profile /etc/bash.bashrc; do
    if [ -f "$file" ]; then
        prompt_and_delete "$file" "nix"
    fi
done

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

# Unset environment variables globally
unset NIX_USER_PROFILE_DIR
unset NIX_PATH



echo "Nix has been removed."