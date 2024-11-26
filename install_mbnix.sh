#!/bin/sh
LIGHT_CYAN_BOLD='\033[01;38;5;87m'
CYAN_BOLD='\033[01;36m'
PINK_BOLD='\033[01;38;5;225m'
RESET='\033[0m'
PINK='\033[38;5;225m'
help () {
    echo "${LIGHT_CYAN_BOLD}Usage: sh install_mbnix.sh${RESET} ${PINK}[MB_WS]${RESET}"
    echo " "
    echo "${PINK}MB_WS${RESET}: The workspace directory for mbnix. Default is ${PINK}$HOME/mbnix.${RESET}"
    echo " "
}
help 

# You just ran curl -L https://mbodi.ai/install.sh | sh
# 1. Clone the mbnix repository to your home directory
# 2. Install Nix in multi-user mode
# 3. Source setup.sh in the mbnix repository

if [ -d "$HOME/mbnix" ]; then
    echo "mbnix already installed. Run 'rm -rf $HOME/mbnix' to reinstall."
else
    git clone https://github.com/mbodiai/mbnix.git "$HOME/mbnix"
fi

cd "$HOME/mbnix" || exit

# Install Nix in multi-user mode
MB_WS="$1"
if [ -z "$MB_WS" ]; then
    export MB_WS="$HOME/mbnix"
fi
sh "$MB_WS/.mbnix/setup/install_nix.sh"

. "$MB_WS/.mbnix/setup.sh"

cd - || exit

