#!/bin/sh
git config --global submodule.recurse true
# Get the user's default shell
# Early shell detection and switching
case "$SHELL" in
    */zsh)
        if [ -z "$ZSH_VERSION" ]; then
            exec zsh "$0" "$@"
        fi
        ;;
    *)
        if [ -x "$(command -v zsh)" ]; then
            exec zsh "$0" "$@"
        fi
        ;;
esac

# ================================
# Shell Configurations
# ================================


export TERM=xterm-256color

if ls --color > /dev/null 2>&1; then
    alias ls='ls -G --color'       # Colorized ls output
    alias ll='ls -alF --color'     # Long format listing
    alias la='ls -A --color'       # All files except . and ..
    alias l='ls -CF --color'       # Classify files with file type indicator
    alias lr='ls -ltr --color'           # list files by reverse date
    alias grep='grep --color=auto' # Colorize grep output
else
    alias ls='ls -G'               # Default ls output
    alias ll='ls -alF'             # Long format listing
    alias la='ls -A'               # All files except . and ..
    alias l='ls -CF'               # Classify files with file type indicator
    alias lr='ls -ltr'             # list files by reverse date
    alias grep='grep'              # Default grep output
fi

list_aliases() {
    # Search for alias definitions in your shell configuration files
    grep -E '^\s*alias ' ~/.zshrc ~/.bashrc 2>/dev/null | while read -r line; do
        # Extract the alias name
        alias_name=$(echo "$line" | sed -E 's/alias ([^=]*)=.*/\1/')

        # Extract the description (comment after the alias definition)
        description=$(echo "$line" | grep -oE '#.*' | sed -E 's/^# //')

        # Print the alias and description
        printf "%-20s : %s\n" "$alias_name" "$description"
    done
}

if [ -z "$MB_WS" ]; then
    export MB_WS="$HOME/mbnix"
fi


if [ -f "$MB_WS/.mbnix/setup-mbnix.sh" ]; then
    . "$MB_WS/.mbnix/setup-mbnix.sh"
fi

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8



USER_SHELL=$(get_user_shell)
echo "User shell: $USER_SHELL"
case "$USER_SHELL" in
*/zsh)
    SHELL_CONFIG="$HOME/.zshrc"
    . "$MB_WS/.mbnix/.zshrc"
    ;;
*/bash)
    SHELL_CONFIG="$HOME/.bashrc"
    . "$MB_WS/.mbnix/.bashrc"
    ;;
*)
    SHELL_CONFIG="$HOME/.profile"
    . "$MB_WS/.mbnix/.zshrc"
    ;;
esac
if ! grep -q ". $MB_WS/.mbnix/setup.sh" "$SHELL_CONFIG"; then
    echo ". $MB_WS/.mbnix/setup.sh" >>"$SHELL_CONFIG"
fi


export as="list_aliases"
alias rs=". \$MB_WS/.mbnix/setup.sh"