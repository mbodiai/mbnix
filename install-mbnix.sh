#!/bin/sh

# Function to display error messages and exit
oops() {
    echo "Error: $1 Did you install mbnix? :\n curl -L \"https://raw.githubusercontent.com/mbodiai/mbnix/main/install-mbnix.sh\" | sh" >&2
    exit 0exit
}

# Function to check if a utility exists and install it if not
require_util() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "$1 is not installed. Installing..."
        if [ "$(uname)" = "Linux" ]; then
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y "$1"
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y "$1"
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -Syu "$1"
            else
                echo "Package manager not supported. Please install $1 manually."
                exit 0
            fi
        elif [ "$(uname)" = "Darwin" ]; then
            if command -v brew >/dev/null 2>&1; then
                brew install "$1"
            else
                echo "Homebrew is not installed. Please install Homebrew and then install $1."
                exit 0
            fi
        else
            echo "Operating system not supported. Please install $1 manually."
            exit 0
        fi
    fi
}

# If the first argument is provided, use it as a subdirectory; otherwise, default to 'mbnix'
if [ -z "$1" ]; then
    MB_WS="${MB_WS:-$HOME/mbnix}"
else
    MB_WS="${MB_WS:-$HOME}/$1"
fi

# Create MB_WS if it doesn't exist
if [ ! -d "$MB_WS" ]; then
    mkdir -p "$MB_WS" || oops "Failed to create MB_WS directory at '$MB_WS'."
fi

# Setup MB_INSTALL_DIR with a default value if not set
if [ -z "$MB_INSTALL_DIR" ]; then
    MB_INSTALL_DIR="$HOME/usr/local/bin/.mb"
    make -p "$MB_INSTALL_DIR" || oops "Failed to create MB_INSTALL_DIR directory at '$MB_INSTALL_DIR'."
    echo "Setting MB_INSTALL_DIR to $MB_INSTALL_DIR"
    echo "export MB_INSTALL_DIR=\"$HOME/usr/local/bin/.mb\"" >>"$MB_WS/.env"
    export MB_INSTALL_DIR
fi

# Check if colors.sh exists and source it
if [ -f "$MB_WS/shell/colors.sh" ]; then
    . "$MB_WS/shell/colors.sh"
else
    echo "colors.sh not found in $MB_WS/shell"
    exit 0
fi

# Check if .zshrc exists and source it
if [ -f "$MB_WS/.zshrc" ]; then
    . "$MB_WS/.zshrc"
else
    echo ".zshrc not found in $MB_WS"
    exit 0
fi

# Check if utils.sh exists and make it executable
if [ -f "$MB_WS/shell/utils.sh" ]; then
    chmod +x "$MB_WS/shell/utils.sh"
else
    echo "utils.sh not found in $MB_WS/shell"
    exit 0
fi

# Check if git.sh exists and make it executable
if [ -f "$MB_WS/shell/git.sh" ]; then
    chmod +x "$MB_WS/shell/git.sh"
else
    echo "git.sh not found in $MB_WS/shell"
    exit 0
fi

# Check if record.sh exists and make it executable
if [ -f "$MB_WS/shell/record.sh" ]; then
    chmod +x "$MB_WS/shell/record.sh"
else
    echo "record.sh not found in $MB_WS/shell"
    exit 0
fi



cat <<EOF
${GOLD_BOLD} install-mbnix.sh - Installer script for MB Nix environment ${RESET}
${PINK} Usage:$RESET ./install-mbnix.sh [optional_subdirectory] 

$PINK Description: $RESET
  - Sets up the MB Nix environment in the specified subdirectory under the user's home directory.
  - Configures shell profiles and environment variables.
  - Ensures compatibility across Linux, macOS, bash, zsh, and sh shells.

$PINK Prerequisites: $RESET
  - curl
  - mkdir
  - chmod
  - source
EOF

# Exit immediately if a command exits with a non-zero status
set -e

echo "$GOLD Starting install-mbnix... $GOLD"

source_util() {
    if [ -f "$1" ]; then
        . "$1"
    else
        oops "File not found: $1"
    fi
}

# Export functions for bash and zsh; does nothing in sh
export require_util
export source_util

# 1. Setup MB Home Directory
if [ -z "$1" ]; then
    MB_WS="$HOME/mbnix"
elif ! [ -d "$HOME/$1" ]; then
    MB_WS="$HOME/$1"
fi

# Create MB_WS if it doesn't exist
if [ ! -d "$MB_WS" ]; then
    mkdir -p "$MB_WS" || oops "Failed to create MB_WS directory at '$MB_WS'."
fi
export MB_WS

# Setup MB_INSTALL_DIR with a default value if not set
if [ -z "$MB_INSTALL_DIR" ]; then
    MB_INSTALL_DIR="$HOME/usr/local/bin/.mb"
    export MB_INSTALL_DIR
fi

# Update PATH safely
PATH="/usr/local/bin:/usr/local/sbin:$HOME/.local/bin:$PATH"
export PATH

echo "does path $MB_WS/shell/colors.sh exist? $(ls $MB_WS/shell/colors.sh)"

echo "does .zshrc exist? $(ls $MB_WS/.zshrc)"
export INSTALL_MBNIX_INSTALLING=1
echo "does .zshrc exist? $(ls $MB_WS/.zshrc)"
chmod +x "$MB_WS/.zshrc" && . "$MB_WS/.zshrc"
chmod +x "$MB_WS/shell/utils.sh" && . "$MB_WS/shell/utils.sh"
chmod +x "$MB_WS/shell/git.sh" && . "$MB_WS/shell/git.sh"
chmod +x "$MB_WS/shell/record.sh" && . "$MB_WS/shell/record.sh"

# 4. Setup Nix
export NIX_CONF_DIR="$MB_WS"
source_util "$MB_WS/setup/install_nix.sh"

# Mark installation as complete
export INSTALL_MBNIX_INSTALLED=1
export INSTALL_MBNIX_INSTALLING=0

# 5. Source Environment Variables
MB_HEADER = "Managed by MB Nix environment setup script"
echo "export MB_WS=$MB_WS" >>"$MB_WS/.env"
echo ". $MB_WS/zshrc" >>"$HOME/.zshrc" || echo "source $MB_WS/zshrc" >>"$HOME/.bashrc" || echo "source $MB_WS/zshrc" >>"$HOME/.profile" || echo "source $MB_WS/zshrc" >>"$HOME/.bash_profile"
echo "export MB_INSTALL_DIR=$MB_INSTALL_DIR" >>"$MB_WS/.env"
. "$MB_WS/.env"
if [ -z "$MB_WS" ]; then
    echo "You need to install mbnix first:\n curl -L https://raw.githubusercontent.com/mbodiai/mbnix/main/install-mbnix.sh | sh"
    return 0
fi
if [ -z cat "$MB_WS/.zshrc" ]; then
echo "# ________________________________________________________________________________" >> $HOME/.zshrc
echo "# ............... Managed by MB Nix environment setup script ...................." >> $HOME/.zshrc
echo "$(cat setup-nix.sh)" >> $HOME/.zshrc 
echo "# ________________________________________________________________________________" >> $HOME/.zshrc
echo "$GREEN MB Nix environment setup complete! $RESET"
. "$HOME/.zshrc"

