# #!/bin/sh
# Function to display error messages and exit

oops() {
    echo "Error: $1" >&2
    echo "Did you install mbnix?"
    echo 'Run: curl -L "https://raw.githubusercontent.com/mbodiai/mbnix/main/install-mbnix.sh" | sh'
    exit 1
}

# Source a script if it exists
source_util_post() {
    SCRIPT_PATH="$1"

    if [ -f "$SCRIPT_PATH" ]; then
        . "$SCRIPT_PATH" || oops "Could not source '$SCRIPT_PATH'."
    else
        oops "Script '$SCRIPT_PATH' not found."
    fi
}

# Get the user's default shell
get_user_shell() {
    getent passwd "$USER" | cut -d: -f7
}
echo "Active shell: $(get_user_shell)"

# Set MB_WS if not set
if [ -z "$MB_WS" ]; then
    echo "No MB_WS found, setting to $HOME/mbnix"
    export MB_WS="$HOME/mbnix"

    # Determine the shell configuration file
    USER_SHELL=$(get_user_shell)
    SHELL_CONFIG=""
    case "$USER_SHELL" in
        */zsh)
            SHELL_CONFIG="$HOME/.zshrc"
            ;;
        */bash)
            SHELL_CONFIG="$HOME/.bashrc"
            ;;
        *)
            SHELL_CONFIG="$HOME/.profile"
            ;;
    esac
    if [ -z cat "$SHELL_CONFIG" | grep "export MB_WS=\"$MB_WS\"" ]; then
        # Append MB_WS export to the shell configuration file
        echo "export MB_WS=\"$MB_WS\"" >>"$SHELL_CONFIG"
        echo "MB_WS exported to $SHELL_CONFIG"
    else
        echo "MB_WS already exported to $SHELL_CONFIG"
    fi

fi
# ================================
# Source colors.sh
# ================================
setup_colors() {
    if ! [ -f "$MB_WS/shell/colors.sh" ]; then
        echo "colors.sh not found in $MB_WS/shell"
    elif [ -z "$MB_COLOR" ]; then
        . "$MB_WS/shell/colors.sh"
    fi
}
# ================================
# Define the mbnix function
# ================================
mbnix_cmd() {
    help() {
        echo "${PINK_BOLD}Usage: ${GOLD_BOLD}mbnix${RESET} ${PINK}[COMMAND]${RESET}"
        echo "${GOLD_BOLD}Commands:${RESET}"
        echo "  shell     Enter the mbnix shell"
        echo "  help      Display this help message"
        echo "  install   Install mbnix"
        echo "  update    Update mbnix"
        echo "  uninstall Uninstall mbnix"
        echo "  env       Display essential environment variables "
        echo "  reset     Reset mbnix configuration"
    }
    shell() {
        if [ -z $IN_NIX_SHELL ]; then
            nix develop .
        else
            echo "Already in a nix shell."
        fi
    }
    if [ -z "$1" ]; then
        help
        shell
    elif [ "$1" = "shell" ]; then
        shell
    elif [ "$1" = "help" ]; then
        help
    elif [ "$1" = "install" ]; then
        echo "$GREEN_BOLD Installing mbnix... $RESET"
        curl -L "https://raw.githubusercontent.com/mbodiai/mbnix/main/install-mbnix.sh" | sh
    elif [ "$1" = "update" ]; then
        echo "Updating mbnix..."
        curl -L "https://raw.githubusercontent.com/mbodiai/mbnix/main/install-mbnix.sh" | sh
    elif [ "$1" = "uninstall" ]; then
        echo "$YELLOW_BOLD Uninstalling mbnix... $RESET"
        # Add uninstall commands here
    elif [ "$1" = "reset" ]; then
        echo "$PINK_BOLD Unsetting mbnix environment variables... $RESET"
        unset MB_WS
        unset MB_INSTALL_DIR
        unset MB_PROMPT
        unset MB_COLOR
        exec "$SHELL"
        return 0
    elif [ "$1" = "env" ]; then
        echo "MB_WS: $MB_WS"
        echo "MB_INSTALL_DIR: $MB_INSTALL_DIR"
        echo "IN_NIX_SHELL: $IN_NIX_SHELL"
        echo "NIX_CONF_DIR: $NIX_CONF_DIR"
        echo "MB_PROMPT: $MB_PROMPT"
        echo "MB_COLOR: $MB_COLOR"
    else
        help
    fi
}
alias mbnix="mbnix_cmd"

# ================================
# Source Nix profile and configure
# ================================
if ! [ -z  /etc/profile.d/nix.sh ]; then
    . /etc/profile.d/nix.sh
fi
export NIX_CONF_DIR="$MB_WS"
if [ -f "$NIX_CONF_DIR/nix.conf" ]; then
    if ! grep -q "experimental-features = nix-command flakes" "$NIX_CONF_DIR/nix.conf"; then
        echo "experimental-features = nix-command flakes" >>"$NIX_CONF_DIR/nix.conf"
    fi
else
    echo "experimental-features = nix-command flakes" >"$NIX_CONF_DIR/nix.conf"
fi

setup_colors