#!/bin/sh
# ===============================
# mbnix guard
# ===============================
if [ -z "$_SETUP_MBNIX_RUNNING" ]; then
    export _SETUP_MBNIX_RUNNING=0
fi
if [ "$_SETUP_MBNIX_RUNNING" -eq 1 ]; then
    return
fi
export _SETUP_MBNIX_RUNNING=1

# ===============================
# mb Configuration
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
LIGHT_BLUE=$'\033[38;5;39m'
LIGHT_BLUE_BOLD=$'\033[01;38;5;39m'
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
    warn "MB_WS is not set. Setting to $HOME/mb."
    export MB_WS="$HOME/mb"
fi
# ================================
# Main mb command
# ================================
mbcmd() {
    mbhelp() {
        echo
        echo "${PINK_BOLD}mb${RESET} (beta) - Package python, cpp, ros, and more in a single, declarative workspace."
        echo " "
        echo "${WHITE_BOLD}USAGE:${RESET}"
        echo "  ${PINK_BOLD}mb${RESET} ${GOLD}[COMMAND]${RESET} [flags]"
        echo
        echo "${WHITE_BOLD}COMMANDS:${RESET}"
        echo "  ${GOLD_BOLD}shell${RESET}         Enter the mb shell"
        echo "  ${GOLD_BOLD}help${RESET}          Display this mbhelp message"
        echo "  ${GOLD_BOLD}reinstall${RESET}     Reinstall mb"
        # echo "  ${GOLD_BOLD}update${RESET}        Update mb"
        echo "  ${GOLD_BOLD}env${RESET}       ${PINK}[py|cpp|ros|cuda|all]${RESET} Display essential environment variables"
        echo "  ${GOLD_BOLD}reset${RESET}         Unset mb environment variables except MB_WS"
        # echo "  ${GOLD_BOLD}doctor${RESET}        Run the mb doctor"
        # echo "  ${GOLD_BOLD}search${RESET}        Search for packages in the mb workspace"
        echo "  ${GOLD_BOLD}extras${RESET}        Install extra packages in the mb workspace"
        echo "  ${GOLD_BOLD}switch${RESET}        Switch between different mb workspaces"
        echo "  ${GOLD_BOLD}prompt${RESET}        Quick prompt toggles"
        echo
        echo "${WHITE_BOLD}FLAGS:${RESET}"
        echo "  ${PINK}--help | -h${RESET}        Show help for the command"
        echo "  ${PINK}--version${RESET}          Show mb version"
        echo
        echo "${WHITE_BOLD}EXAMPLES:${RESET}"
        echo "  ${GOLD_BOLD}mb shell${RESET}       Enter the mb shell"
        echo "  ${GOLD_BOLD}mb env${RESET} cuda    Show CUDA-related environment variables"
        echo "  ${GOLD_BOLD}mb reset${RESET}       Reset all mb environment variables except MB_WS"
        echo
        echo "${WHITE_BOLD}LEARN MORE:${RESET}"
        echo "  Visit the mb GitHub repository: ${GOLD_BOLD}https://github.com/mbodiai/mb.git${RESET}"
        echo
    }

    shell() {
        if [ -z "$IN_NIX_SHELL" ]; then
            nix develop . || oops "Failed to start the nix shell."
        else
            echo "${PINK_BOLD}Already in a nix shell.${RESET}"
        fi
    }
 

    cmd="$1"
    first_arg="$1"
    subcmd="$2"
    if [ "$cmd" = "--help" ] || [ "$cmd" = "-h" ] || [ "$cmd" = "help" ]; then
        mbhelp
        cmd="$2"
        subcmd="$3"
    fi

    if [ -z "$first_arg" ]; then
        mbhelp
    elif [ "$cmd" = "shell" ]; then
        shell
    elif [ "$cmd" = "help" ] || [ "$cmd" = "--help" ] || [ "$cmd" = "-h" ]; then
        mbhelp
        return
    elif [ "$cmd" = "reinstall" ]; then
        echo "${GOLD_BOLD}Installing mb...${RESET} from $MB_INSTALL_URL"
        curl -L "$MB_INSTALL_URL" | sh || oops "Failed to reinstall mb."
    elif [ "$cmd" = "update" ]; then
        echo "${GOLD_BOLD}Updating mb...${RESET}"
        curl -L "$MB_INSTALL_URL" | sh || oops "Failed to update mb."
    elif [ "$cmd" = "reset" ]; then
        if [ "$subcmd" = "--help" ] || [ "$subcmd" = "-h" ]; then
            subcmd="$4"
            echo ""
            echo "${WHITE}Usage:"
            echo "${RESET} ${GOLD}mb reset${RESET} [-q|--quiet]"
            echo ""
            return
        fi
        anim=1
        if [ "$subcmd" = "-q" ] || [ "$subcmd" = "--quiet" ]; then
            unset anim
        fi
        if [ -n "$anim" ]; then
            echo " "
            animate_message "Unsetting mb environment variables" 0.17 "$PINK" 1 1
        fi
        if [ -n "$anim" ]; then
            echo " "
        fi
        unset MB_PROMPT
        unset MB_COLOR
        # unset MB_SOURCED
        unset MB_SETUP
        unset MB_EXTRAS
        unset MB_GIT
        unset MB_TREE
        unset MB_DOCTOR
        unset MB_SEARCH
        unset MB_BENCH
        unset IN_NIX_SHELL
        unset MB_ENVVARS
        . "$MB_WS/.mbnix/setup_mbnix.sh"
    elif [ "$1" = "env" ]; then
        . "$MB_WS/.mbnix/utils/listenv.sh"
        list_envs "$2"
    elif [ "$cmd" = "extras" ]; then
        unset MB_EXTRAS MB_GIT MB_TREE MB_DOCTOR MB_SEARCH MB_BENCH MB_SETUP
        . "$MB_WS/.mbnix/setup_mbnix.sh"
        return
    elif [ "$cmd" = "prompt" ]; then
        if [ -z "$subcmd" ]; then
            echo "${RED_BOLD}ERROR: MISSING ARGUMENT${RESET}"
            echo "  ${RED}Please provide a prompt toggle.${RESET}"
            toggle_prompt --help
            return
        fi
        toggle_prompt "$subcmd"
    elif [ "$cmd" = "switch" ]; then
        if [ -z "$subcmd" ]; then
            echo "${RED_BOLD}ERROR: MISSING ARGUMENT${RESET}"
            echo "  ${RED}Please provide a workspace name.${RESET}"
            echo " "
            return
        fi
        if [ -d "$subcmd" ]; then
            export MB_WS="$subcmd"
            unset MB_SETUP
            . "$MB_WS/.mbnix/setup_mbnix.sh"
        else
            echo "${RED_BOLD}ERROR: INVALID WORKSPACE${RESET}"
            echo "  ${RED}Workspace '$subcmd' not found.${RESET}"
            echo " "
        fi
    else

        mbhelp
        echo "${RED_BOLD}ERROR: UNKOWN COMMAND${RESET}"
        echo "  ${RED}Command '$first_arg' not recognized.${RESET}"
        echo " "
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



mbcmd prompt on
alias mb="mbcmd"
unset _SETUP_MBNIX_RUNNING
