#!/bin/sh
if [ -z "$_SETUP_MBWS_RUNNING" ]; then
    export _SETUP_MBWS_RUNNING=0
fi

if [ "$_SETUP_MBWS_RUNNING" -eq 1 ]; then
    return
fi
export _SETUP_MBWS_RUNNING=1

git config --global submodule.recurse true

# ================================
# Shell Configurations
# ================================
get_user_shell() {
    ps -p $$ -o comm=
}

export TERM=xterm-256color

if ls --color > /dev/null 2>&1; then
    alias ls='ls --color=auto' # Enable color support for ls
    alias ll='ls -alF --color=auto' # List all files with details
    alias la='ls -A --color=auto' # List all files including hidden files
    alias l='ls -CF --color=auto' # List files in columns
    alias lr='ls -ltr --color=auto' # List files in reverse order of modification time
    alias grep='grep --color=auto' # Enable color support for grep
else
    alias ls='ls' # Disable color support for ls
    alias ll='ls -alF' # List all files with details
    alias la='ls -A' # List all files including hidden files
    alias l='ls -CF' # List files in columns
    alias lr='ls -ltr' # List files in reverse order of modification time
    alias grep='grep' # Disable color support for grep
fi
list_aliases() {
    # Ensure MB_WS is set
    if [ -z "$MB_WS" ]; then
        echo "MB_WS environment variable is not set. Setting to \$HOME/mbnix."
        export MB_WS="$HOME/mbnix"
    fi

    # Create a temporary file to store the list of shell config files
    files_list=$(mktemp) || {
        echo "Failed to create temporary file."
        return 1
    }
    trap 'rm -f "$files_list"' EXIT

    # Define the current script name to exclude it from the search
    current_script="setup.sh"

    # Find all relevant shell config files excluding the current script
    find "$MB_WS" -type f \( -name "*.sh" -o -name ".zshrc" -o -name ".bashrc" \) ! -name "$current_script" > "$files_list" 2>/dev/null

    # Check if any files were found
    if [ ! -s "$files_list" ]; then
        echo "No shell configuration files found in \$MB_WS."
        return 0
    fi

    # Initialize a list to store aliases
    aliases_output=""

    # Read each file and extract aliases with comments
    while IFS= read -r file; do
        if [ -s "$file" ]; then
            while IFS= read -r line; do
                alias_name=$(printf "%s" "$line" | sed -E 's/^[[:space:]]*alias[[:space:]]+([^=]+)=.*/\1/')
                description=$(printf "%s" "$line" | sed -n 's/.*# *//p')
                [ -z "$description" ] && description=""
                aliases_output=$(printf "%s\n%-20s : %s" "$aliases_output" "$alias_name" "$description")
            done < <(grep -E '^\s*alias' "$file")
        else
            echo "Skipping empty or invalid file: $file" >&2
        fi
    done < "$files_list"

    # Print the collected aliases
    printf "%s\n" "$aliases_output"

    # Manually add the specific alias
    printf "%-20s : %s\n" "rs" "Reload the mb shell configuration."
}



USER_SHELL=$(get_user_shell)

if [ -z "$MB_WS" ]; then
    echo "MB_WS environment variable is not set. Setting to $HOME/mbnix."
    export MB_WS="$HOME/mbnix"
fi
case "$USER_SHELL" in
zsh)
    SHELL_CONFIG="$HOME/.zshrc"

    if [ -f "$MB_WS/.mbnix/.zshrc" ] && ! grep -q "source $MB_WS/.mbnix/.zshrc" < "$SHELL_CONFIG"; then
        echo "source $MB_WS/.mbnix/.zshrc" >>"$SHELL_CONFIG"
    fi
    ;;
bash)
    SHELL_CONFIG="$HOME/.bashrc"
    if [ -f "$MB_WS/.mbnix/.bashrc" ] && ! grep -q "source $MB_WS/.mbnix/.bashrc" <  "$SHELL_CONFIG" ; then
        echo "source $MB_WS/.mbnix/.bashrc" >>"$SHELL_CONFIG"
    fi
    ;;
*)
    echo "Unsupported shell: $USER_SHELL"
    return 1
    ;;
esac



if [ -z "$MB_WS" ]; then
    export MB_WS="$HOME/mbnix"
fi

if [ -f "$MB_WS/.mbnix/utils/colors.sh" ]; then
    . "$MB_WS/.mbnix/utils/colors.sh"
fi

if [ -f "$MB_WS/.mbnix/setup_prompt.sh" ]; then
    . "$MB_WS/.mbnix/setup_prompt.sh"
fi

if [ -f "$MB_WS/.mbnix/setup_mbnix.sh" ]; then
    . "$MB_WS/.mbnix/setup_mbnix.sh"
fi



if [ -n "$MB_EXTRAS" ] || [ "$1" = "extras" ]; then
    echo "Sourcing extras"
    . "$MB_WS/.mbnix/utils/extras.sh"
fi


alias als="list_aliases" # List all aliases and their descriptions.
alias rs="mb reset &&  . \$MB_WS/.mbnix/setup.sh" # Reload the mb shell configuration.
unset _SETUP_MBWS_RUNNING