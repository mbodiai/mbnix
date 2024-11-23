#!/bin/sh
# Define color variables using ANSI escape codes
GOLD=$'\033[38;5;223m'
GOLD_BOLD=$'\033[01;38;5;223m'
RESET=$'\033[0m'
RED=$'\033[31m'
RED_BOLD=$'\033[01;31m'
GREEN=$'\033[32m'
GREEN_BOLD=$'\033[01;32m'
PINK=$'\033[38;5;225m'
PINK_BOLD=$'\033[01;38;5;225m'
YELLOW=$'\033[33m'
YELLOW_BOLD=$'\033[01;33m'
BLUE=$'\033[34m'
BLUE_BOLD=$'\033[01;34m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
LIGHT_CYAN=$'\033[38;5;87m'
LIGHT_CYAN_BOLD=$'\033[01;38;5;87m'
CYAN_BOLD=$'\033[01;36m'



warn() {
    printf "%b\n" "${YELLOW}Warning:${RESET} $1" >&2
}

# Validate MB_WS environment variable
if [ -z "$MB_WS" ]; then
    warn "MB_WS is not set. Setting to $HOME/MBNIX."
fi

# Validate MB_COLOR environment variable
validate_mb_color() {
    if [ -z "$MB_COLOR" ]; then
        MB_COLOR="PINK_BOLD"  # Default color name
    fi

    case "$MB_COLOR" in
        RED|GREEN|PINK|CYAN|YELLOW|BLUE|MAGENTA|PINK_BOLD|CYAN_BOLD)
            eval "MB_COLOR=\"\$$MB_COLOR\""
            ;;
        *$'\033'*)
            # MB_COLOR is already an escape sequence; accept it
            ;;
        *)
            oops "Invalid MB_COLOR value: $MB_COLOR. Must be a valid color name or escape code."
            MB_COLOR="$PINK_BOLD"  # Fallback to default escape code
            ;;
    esac
}


# Adjusted animate_message function with animation flag
animate_message() {
    message="${1:-}"
    sleeptime="${2:-}"
    color="${3:-}"
    startat="${4:-1}"
    animate_msg="${5:-1}"  # 1 to animate message, 0 to display instantly

    # Accelerated delays
    delay=0.05       # Speed up character display
    dots_delay=0.1   # Speed up dots animation
    max_dots=3

    # Display the message
    printf "%b" "$color"
    if [ "$animate_msg" -eq 1 ]; then
        # Animate message one letter at a time
        i="$startat"
        message_length=$(printf '%s' "$message" | wc -c)
        while [ "$i" -le "$message_length" ]; do
            char=$(printf '%s' "$message" | cut -c "$i")
            printf "%b" "$char"
            sleep "$delay"
            i=$((i + 1))
        done
    else
        # Display message instantly
        printf "%b" "$message"
    fi

    # Animate dots after the message
    end_time=$(( $(date +%s) + sleeptime ))
    dot_count=0
    while [ "$(date +%s)" -lt "$end_time" ]; do
        dots=""
        num_dots=$(( (dot_count % max_dots) + 1 ))
        j=1
        while [ "$j" -le "$num_dots" ]; do
            dots="$dots."
            j=$((j + 1))
        done
        printf "\r%b%b%b%b" "$color" "$message" "$dots" "$RESET"
        sleep "$dots_delay"
        dot_count=$((dot_count + 1))
    done
    printf "%b\n" "$RESET"
}




MB_INSTALL_URL="https://mbodi.ai/install.sh"
oops() {
    echo "Error: $1" >&2
    echo "Did you install mbnix?"
    echo "Run: curl -L $MB_INSTALL_URL | sh"
    exit 1
}

# Source a script if it exists
source_util_post() {
    SCRIPT_PATH="$1"

    if [ -f "$SCRIPT_PATH" ]; then
        # shellcheck source=/dev/null
        . "$SCRIPT_PATH" || oops "Could not source '$SCRIPT_PATH'."
    else
        oops "Script '$SCRIPT_PATH' not found."
    fi
}


# Set MB_WS if not set
if [ -z "$MB_WS" ]; then
    export MB_WS="$HOME/mbnix"
fi
if [ -z "$MB_SOURCED" ]; then
    # Animate both message and dots
    animate_message "building your workspace" 1 "$GOLD_BOLD" 1 1

    # Display message instantly, animate only dots
    animate_message "from mbodi ai" 1 "$PINK_BOLD" 1 0
    export MB_SOURCED=1

fi
# ================================
# Main mbnix command
# ================================
mbnix_cmd() {
    help() {
        echo "${PINK_BOLD}Usage: ${GOLD_BOLD}mbnix${RESET} ${PINK}[COMMAND]${RESET}"
        echo "${LIGHT_CYAN_BOLD}Commands:${RESET}"
        echo "  ${GOLD_BOLD}shell${RESET}     Enter the mbnix shell"
        echo "  ${GOLD_BOLD}help${RESET}      Display this help message"
        echo "  ${GOLD_BOLD}reinstall${RESET} Reinstall mbnix"
        echo "  ${GOLD_BOLD}update${RESET}    Update mbnix"
        echo " ${GOLD_BOLD}env${RESET}${BLUE}[py|cpp|ros|cuda|all]${BLUE} Display essential environment variables"
        echo " ${GOLD_BOLD}reset${RESET}     Unset mbnix environment variables"
        echo " ${GOLD_BOLD}list${RESET}      List all available commands"

    }
    shell() {
        if [ -z "$IN_NIX_SHELL" ]; then
            nix develop .
        else
            echo "Already in a nix shell."
        fi
    }

    list_envs() {
            list_env_py() {
                echo "Python/Conda environment variables:"
                env | grep -iE "PYTHON|VIRTUAL_ENV|CONDA|PIP|PATH"
                which python3
            }

            list_env_cpp() {
                echo "C++/Build environment variables:"
                env | grep -iE "CXX|CC|CMAKE|MAKE|BUILD|LD_LIBRARY|INCLUDE"
            }

            list_env_ros() {
                echo "ROS2 environment variables:"
                env | grep -iE "ROS|AMENT|COLCON|GAZEBO|CYCLONE"
            }

            list_env_cuda() {
                echo "CUDA/GPU environment variables:"
                env | grep -iE "CUDA|NVCC|NVIDIA|GPU|NCCL|TENSORRT"
                nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv 2>/dev/null
            }

            list_env_all() {
                list_env_py
                echo "---"
                list_env_cpp  
                echo "---"
                list_env_ros
                echo "---"
                list_env_cuda
            }

      
            case "$1" in
                    py|python) list_env_py ;;
                    cpp) list_env_cpp ;;
                    ros) list_env_ros ;;
                    cuda) list_env_cuda ;;
                    all) list_env_all ;;
                    *) echo "Usage: $0 env {py|cpp|ros|cuda|all}" ;;
            esac

        

    }
    if [ -z "$1" ]; then
        help
    elif [ "$1" = "shell" ]; then
        shell
    elif [ "$1" = "help" ]; then
        help
    elif [ "$1" = "reinstall" ]; then
        echo "$GOLD_BOLD Installing mbnix... from $MB_INSTALL_URL $RESET"
        curl -L "$MB_INSTALL_URL" | sh
    elif [ "$1" = "update" ]; then
        echo "Updating mbnix..."
        curl -L "$MB_INSTALL_URL" | sh
        echo "$GOLD_BOLD Uninstalling mbnix... $RESET"
        
    elif [ "$1" = "reset" ]; then
        echo "$PINK_BOLD Unsetting mbnix environment variables... $RESET"
        unset MB_WS
        unset MB_INSTALL_DIR
        unset MB_PROMPT
        unset MB_COLOR
        unset MB_SOURCED
        
        exec "$SHELL"
        return 0
    elif [ "$1" = "env" ]; then
        echo "MB_WS: $MB_WS"
        echo "MB_INSTALL_DIR: $MB_INSTALL_DIR"
        echo "IN_NIX_SHELL: $IN_NIX_SHELL"
        echo "NIX_CONF_DIR: $NIX_CONF_DIR"

        if [ -n "$2" ]; then
            list_envs "$2"
        fi
    else
        help
    fi
}


# ================================
# Source Nix profile and configure
# ================================
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ] && [ -z "$NIX_PROFILES" ]; then
  # shellcheck disable=SC1091
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
export NIX_CONF_DIR="$MB_WS"
if [ -f "$NIX_CONF_DIR/nix.conf" ]; then
    if ! grep -q "experimental-features = nix-command flakes" "$NIX_CONF_DIR/nix.conf"; then
        echo "experimental-features = nix-command flakes" >>"$NIX_CONF_DIR/nix.conf"
    fi
else
    echo "experimental-features = nix-command flakes" >"$NIX_CONF_DIR/nix.conf"
fi

# shellcheck disable=SC1091
. "$MB_WS/.mbnix/setup-prompt.sh"



alias mb="mbnix_cmd"