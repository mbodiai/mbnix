#!/bin/sh

# ===============================
# MBNIX Configuration
# ===============================
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
WHITE_BOLD=$'\033[01;37m'
warn() {
    printf "%b\n" "${YELLOW}Warning:${RESET} $1" >&2
}

# Validate MB_WS environment variable
if [ -z "$MB_WS" ]; then
    warn "MB_WS is not set. Setting to $HOME/MBNIX."
    export MB_WS="$HOME/mbnix"
fi

# Validate MB_COLOR environment variable
validate_mb_color() {
    if [ -z "$MB_COLOR" ]; then
        MB_COLOR="PINK_BOLD" # Default color name
    fi

    case "$MB_COLOR" in
    RED | GREEN | PINK | CYAN | YELLOW | BLUE | MAGENTA | PINK_BOLD | CYAN_BOLD)
        eval "MB_COLOR=\"\$$MB_COLOR\""
        ;;
    *$'\033'*)
        # MB_COLOR is already an escape sequence; accept it
        ;;
    *)
        oops "Invalid MB_COLOR value: $MB_COLOR. Must be a valid color name or escape code."
        MB_COLOR="$PINK_BOLD" # Fallback to default escape code
        ;;
    esac
}

# Adjusted animate_message function with animation flag
animate_message() {
    message="${1:-}"
    sleeptime="${2:-}"
    color="${3:-}"
    startat="${4:-1}"
    animate_msg="${5:-1}" # 1 to animate message, 0 to display instantly

    # Accelerated delays
    delay=0.05     # Speed up character display
    dots_delay=0.1 # Speed up dots animation
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
    end_time=$(($(date +%s) + sleeptime))
    dot_count=0
    while [ "$(date +%s)" -lt "$end_time" ]; do
        dots=""
        num_dots=$(((dot_count % max_dots) + 1))
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

# ================================
# Source utility functions
# ================================
MB_INSTALL_URL="https://mbodi.ai/install.sh"

oops() {
    echo "${PINK_BOLD}Error:${RESET} $1" >&2
    echo "Did you install mbnix?"
    echo "Run: curl -L $MB_INSTALL_URL | sh"
    exit 1
}

source_util_post() {
    SCRIPT_PATH="$1"
    if [ -f "$SCRIPT_PATH" ]; then
        # shellcheck source=/dev/null
        . "$SCRIPT_PATH" || oops "Could not source '$SCRIPT_PATH'."
    else
        oops "Script '$SCRIPT_PATH' not found."
    fi
}

if [ -z "$MB_SOURCED" ]; then
    animate_message "building your workspace" 1 "$GOLD_BOLD" 1 1
    animate_message "from mbodi ai" 1 "$PINK_BOLD" 1 0
    export MB_SOURCED=1
fi

# ================================
# Main mbnix command
# ================================
mbcmd() {
    mbhelp() {
        echo
        echo "${PINK_BOLD}mb${RESET} (beta) - Package python, cpp, ros, and more in a single, declarative workspace."
        echo " "
        echo "${LIGHT_CYAN_BOLD}USAGE:${RESET}"
        echo "  ${PINK_BOLD}mb${RESET} ${GOLD}[COMMAND]${RESET} [flags]"
        echo
        echo "${LIGHT_CYAN_BOLD}COMMANDS:${RESET}"
        echo "  ${GOLD_BOLD}shell${RESET}         Enter the mbnix shell"
        echo "  ${GOLD_BOLD}mbhelp${RESET}          Display this mbhelp message"
        echo "  ${GOLD_BOLD}reinstall${RESET}     Reinstall mbnix"
        echo "  ${GOLD_BOLD}update${RESET}        Update mbnix"
        echo "  ${GOLD_BOLD}env${RESET}           ${PINK}[py|cpp|ros|cuda|all]${RESET} Display essential environment variables"
        echo "  ${GOLD_BOLD}reset${RESET}         Unset mbnix environment variables except MB_WS"
        echo "  ${GOLD_BOLD}list${RESET}          List all available commands"
        echo
        echo "${LIGHT_CYAN_BOLD}FLAGS:${RESET}"
        echo "  ${PINK}--mbhelp${RESET}        Show mbhelp for the command"
        echo "  ${PINK}--version${RESET}     Show mbnix version"
        echo
        echo "${LIGHT_CYAN_BOLD}EXAMPLES:${RESET}"
        echo "  ${GOLD_BOLD}mb shell${RESET}               Enter the mbnix shell"
        echo "  ${GOLD_BOLD}mb env${RESET} cuda             Show CUDA-related environment variables"
        echo "  ${GOLD_BOLD}mb reset${RESET}                Reset all mbnix environment variables"
        echo
        echo "${LIGHT_CYAN_BOLD}LEARN MORE:${RESET}"
        echo "  Visit the mbnix GitHub repository: ${GOLD_BOLD}https://github.com/mbodiai/mbpy.git${RESET}"
        echo
    }

    shell() {
        if [ -z "$IN_NIX_SHELL" ]; then
            nix develop . || oops "Failed to start the nix shell."
        else
            echo "${PINK_BOLD}Already in a nix shell.${RESET}"
        fi
    }

    list_envs() {
        mbhelp_env() {
            echo
            echo "${PINK_BOLD}Usage:${RESET} ${PINK_BOLD}mb env${RESET} ${GOLD_BOLD}{extras|py|cpp|ros|cuda|all}${RESET}"
            echo
        }

        list_env_py() {
            echo
            echo "${PINK_BOLD}Python/Conda environment variables:${RESET}"
            echo "------------------------------------"
            env | grep -iE "PYTHON|VIRTUAL_ENV|CONDA|PIP|PATH" || echo "No Python/Conda environment variables set."

            for var in PYTHONPATH VIRTUAL_ENV CONDA_PREFIX CONDA_DEFAULT_ENV; do
                if printenv "$var" >/dev/null 2>&1; then
                    echo "$var=$(printenv "$var")"
                else
                    echo "$var="
                fi
            done

            if command -v python3 >/dev/null 2>&1; then
                echo "Python executable: $(which python3)"
            else
                echo "Python executable: Not found"
            fi
            echo
        }

        list_env_cpp() {
            echo
            echo "${GOLD_BOLD}C++/Build environment variables:${RESET}"
            echo "--------------------------------"
            env | grep -iE "CXX|CC|CMAKE|MAKE|BUILD|LD_LIBRARY|INCLUDE" || echo "No C++/Build environment variables set."

            for var in CXX CC CMAKE_PREFIX_PATH LD_LIBRARY_PATH INCLUDE_PATH; do
                if printenv "$var" >/dev/null 2>&1; then
                    echo "$var=$(printenv "$var")"
                else
                    echo "$var="
                fi
            done
            echo
        }

        list_env_ros() {
            echo
            echo "${LIGHT_CYAN_BOLD}ROS2 environment variables:${RESET}"
            echo "---------------------------"
            env | grep -iE "ROS|AMENT|COLCON|GAZEBO|CYCLONE" || echo "No ROS2 environment variables set."

            for var in ROS_DISTRO ROS_VERSION ROS_PACKAGE_PATH AMENT_PREFIX_PATH; do
                if printenv "$var" >/dev/null 2>&1; then
                    echo "$var=$(printenv "$var")"
                else
                    echo "$var="
                fi
            done
            echo
        }

        list_env_cuda() {
            echo
            echo "${BLUE_BOLD}CUDA/GPU environment variables:${RESET}"
            echo "--------------------------------"
            env | grep -iE "CUDA|NVCC|NVIDIA|GPU|NCCL|TENSORRT" || echo "No CUDA environment variables set."

            for var in CUDA_HOME CUDA_PATH NVIDIA_DRIVER_CAPABILITIES; do
                if printenv "$var" >/dev/null 2>&1; then
                    echo "$var=$(printenv "$var")"
                else
                    echo "$var="
                fi
            done

            echo "NVIDIA GPU Information:"
            if command -v nvidia-smi >/dev/null 2>&1; then
                # Run nvidia-smi and ensure unique lines
                nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>/dev/null | sort | uniq || echo "No NVIDIA GPUs found."
            else
                echo "nvidia-smi not found. Unable to query GPU information."
            fi
            echo
        }

        list_env_all() {
            list_env_py
            echo
            echo "---"
            echo
            list_env_cpp
            echo
            echo "---"
            echo
            list_env_ros
            echo
            echo "---"
            echo
            list_env_cuda
            echo
        }

        case "$1" in
        py | python)
            list_env_py
            ;;
        cpp)
            list_env_cpp
            ;;
        ros)
            list_env_ros
            ;;
        cuda)
            list_env_cuda
            ;;
        all)
            list_env_all
            ;;
        mbhelp | *)
            mbhelp_env
            ;;
        esac
    }

    if [ -z "$1" ]; then
        mbhelp
    elif [ "$1" = "shell" ]; then
        shell
    elif [ "$1" = "mbhelp" ]; then
        mbhelp
    elif [ "$1" = "reinstall" ]; then
        echo "${GOLD_BOLD}Installing mbnix...${RESET} from $MB_INSTALL_URL"
        curl -L "$MB_INSTALL_URL" | sh || oops "Failed to reinstall mbnix."
    elif [ "$1" = "update" ]; then
        echo "${GOLD_BOLD}Updating mbnix...${RESET}"
        curl -L "$MB_INSTALL_URL" | sh || oops "Failed to update mbnix."
    elif [ "$1" = "reset" ]; then
        echo " "
        echo "${PINK}Unsetting mbnix environment variables...${RESET}"
        echo " "
        unset MB_PROMPT
        unset MB_COLOR
        unset MB_SOURCED
        unset MB_SETUP
        unset MB_EXTRAS
        unset MB_GIT
        unset MB_TREE
        unset MB_DOCTOR
        unset MB_SEARCH
        unset MB_BENCH
        unset IN_NIX_SHELL
        unset MB_ENVVARS
        unset MB_RC
    elif [ "$1" = "env" ]; then
        if [ "$2" = "--mbhelp" ]; then
            list_envs mbhelp
        elif [ -n "$2" ] && ! [ "$2" = "extras" ]; then
            list_envs "$2"
        else
            echo "MB_WS: $MB_WS"
            echo "MB_SOURCED: $MB_SOURCED"
            echo "MB_EXTRAS: $MB_EXTRAS"
            echo "MB_INSTALL_DIR: $MB_INSTALL_DIR"
            if [ -n "$2" ] && [ "$2" = "extras" ]; then
                echo "MB_EXTRAS: $MB_EXTRAS"
                echo "MB_GIT: $MB_GIT"
                echo "MB_TREE: $MB_TREE"
                echo "MB_DOCTOR: $MB_DOCTOR"
                echo "MB_SEARCH: $MB_SEARCH"
                echo "MB_BENCH: $MB_BENCH"

            fi
           
        fi
    else
        echo "${PINK_BOLD}Unknown command:${RESET} $1"
        mbhelp
    fi
}


# ================================
# Source Nix profile and configure
# ================================
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ] && [ -z "$NIX_PROFILES" ] && [ -z "$IN_NIX_SHELL" ]; then
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

alias mb="mbcmd" # Package python, cpp, & ros, environments in a single, declarative workspace.
alias set_missing_env_vars="setup_envs" # Reset missing environment variables
alias reset_env_vars="reset_envs" # Reset environment variables set by setup_envs