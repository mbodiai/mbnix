#!/bin/sh
if [ -n "$MB_SETUP" ] && [ "$MB_SHLVL" -eq "$SHLVL" ]; then
    echo "MB_SETUP already sourced. Run 'unset MB_SETUP' to reload."
    return
fi
export MB_SETUP="sourced"
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
source_unix_lang() {
    # Get available locales
    available_locales=$(locale -a 2>/dev/null)
    
    # Try common UTF-8 variants
    for locale in "en_US.UTF-8" "en_US.utf8" "en_US.UTF8" "C.UTF-8"; do
        if echo "$available_locales" | grep -q "^$locale$"; then
            export LANG="$locale"
            export LC_ALL="$locale"
            return 0
        fi
    done
    
    # Fallback to C locale if no UTF-8 locale found
    export LANG=C
    export LC_ALL=C
    echo "Warning: No UTF-8 locale found. Using C locale." >&2
}



USER_SHELL=$(get_user_shell)
source_unix_lang 
if [ -z "$MB_WS" ]; then
    echo "MB_WS environment variable is not set. Setting to $HOME/mbnix."
    export MB_WS="$HOME/mbnix"
fi
case "$USER_SHELL" in
zsh)
    SHELL_CONFIG="$HOME/.zshrc"

    [ -f "$MB_WS/.mbnix/.zshrc" ] && [ -z $MB_RC ] && . "$MB_WS/.mbnix/.zshrc"
    ;;
bash)
    SHELL_CONFIG="$HOME/.bashrc"
    [ -f "$MB_WS/.mbnix/.bashrc" ] && [ -z $MB_RC ] && . "$MB_WS/.mbnix/.bashrc"
    ;;
*)
    SHELL_CONFIG="$HOME/.profile"
    [ -f "$MB_WS/.mbnix/.zshrc" ] && [ -z $MB_RC ] && . "$MB_WS/.mbnix/.zshrc"
    ;;
esac

if ! grep -q ". $MB_WS/.mbnix/setup.sh" "$SHELL_CONFIG"; then
    echo ". $MB_WS/.mbnix/setup.sh" >>"$SHELL_CONFIG"
fi

if [ -z "$MB_WS" ]; then
    export MB_WS="$HOME/mbnix"
fi

if [ -f "$MB_WS/.mbnix/setup_mbnix.sh" ] || ! [ "$MB_SHLVL" -eq "$SHLVL" ]; then
    . "$MB_WS/.mbnix/setup_mbnix.sh"
fi

if [ -f "$MB_WS/.mbnix/setup_prompt.sh" ] || ! [ "$MB_SHLVL" -eq "$SHLVL" ]; then
    . "$MB_WS/.mbnix/setup_prompt.sh"
fi

alias als="list_aliases" # List all aliases and their descriptions.
alias rs="mb reset &&  . \$MB_WS/.mbnix/setup.sh" # Reload the mb shell configuration.
if [ -n "$MB_EXTRAS" ] || [ "$1" = "extras" ]; then
    . "$MB_WS/.mbnix/utils/extras.sh"
fi
export MB_SHLVL=$SHLVL
