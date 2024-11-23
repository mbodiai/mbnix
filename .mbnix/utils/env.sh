#!/bin/sh
#!/bin/sh
TERM=xterm-256color
# Function to use bat for pretty help pages
man_command() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;31m") \
        LESS_TERMCAP_md=$(printf "\e[1;31m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
        man "$@" | $BAT --paging=always --language=bash --color=always
}

# Function to display help messages prettily
help_command() {
    "$@" --help | $BAT --language=bash --color=always --theme=ansi -
}

bat_echo() {
    echo "$@" | $BAT --color=always --theme=ansi --plain -
}

# Helper function to determine the appropriate bat command
bat_cmd() {
    if command -v bat >/dev/null 2>&1; then
        echo "bat"
    elif command -v batcat >/dev/null 2>&1; then
        echo "batcat"
    else
        echo "cat"
    fi
}

# Assign the bat command once
BAT=$(bat_cmd)

OS_TYPE="$(uname -s)"

# Helper function to display timestamps if enabled
get_mod_time() {
    file="$1"
    if [ "$(uname -s)" = "Darwin" ]; then
        # macOS
        stat -f "Modified: %Sm" -t "%b %d, %Y" "$file"
    else
        # Linux
        stat -c "Modified: %b %d, %Y" "$file"
    fi
}

# Helper function for bat preview with line limitation
preview_file() {
    local file="$1"
    local lines="$2"
    echo "File: $file"
    get_mod_time "$file"
    if [ -n "$BAT" ]; then
        $BAT --line-range=1:"$lines" "$file" || echo "Error displaying file: $file"
    else
        cat "$file" | head -n "$lines" || echo "Error displaying file: $file"
    fi
    printed_lines=$((printed_lines + lines))
    echo
}

# Function to ensure a dependency is installed
ensure_dependency() {
    cmd="$1"
    pkg="$2"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        printf "Dependency '%s' is not installed.\n" "$cmd"
        read -r "Would you like to install it now? [Y/n]: " response
        response=$(echo "$response" | tr '[:upper:]' '[:lower:]') # to lowercase
        if [ "$response" = "y" ] || [ "$response" = "yes" ] || [ -z "$response" ]; then
            install_dependency "$cmd" "$pkg"
        else
            printf "Please install '%s' manually.\n" "$pkg"
        fi
    fi
}

# Function to install a dependency based on the OS and available package manager
install_dependency() {
    cmd="$1"
    pkg="$2"

    if [ "$OS_TYPE" = "Darwin" ]; then
        if ! command -v brew >/dev/null 2>&1; then
            printf "Homebrew is not installed. Please install it from https://brew.sh/ and re-run the script.\n"
        fi
        printf "Installing '%s' using Homebrew...\n" "$pkg"
        brew install "$pkg"
    elif [ "$(uname)" = "Linux" ]; then
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            sudo apt-get install -y "$pkg"
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y "$pkg"
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y "$pkg"
        elif command -v python3 -m pipx >/dev/null 2>&1; then
            pipx install "$pkg"
        else
            printf "No supported package manager found (apt, yum, dnf). Please install '%s' manually.\n" "$pkg"
        fi
    else
        printf "Unsupported OS: %s. Please install '%s' manually.\n" "$OS_TYPE" "$pkg"
    fi

    # Verify installation
    if ! command -v "$cmd" >/dev/null 2>&1; then
        pipx install "$pkg"
    fi
}

# Initial setup: Check and install dependencies
initial_setup() {
    # List of dependencies: command -> package name
    dependencies="tree:tree rg:ripgrep bat:bat git:git pyclean:pyclean find:find"

    for dep in $dependencies; do
        cmd="${dep%%:*}"
        pkg="${dep##*:}"

        # Special handling: check for 'bat'
        if [ "$cmd" = "bat" ]; then
            continue
        fi
        if [ "$cmd" = "pyclean" ] && ! command -v pyclean >/dev/null 2>&1; then
            pipx install pyclean --force
            pipx ensurepath
            continue
        fi

        if ! command -v "$cmd" >/dev/null 2>&1; then
            # For 'bat', check 'bat'
            if [ "$cmd" = "bat" ]; then
                if ! command -v bat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
                    ensure_dependency "bat" "bat"
                fi
            else
                ensure_dependency "$cmd" "$pkg"
            fi
        fi
    done

    # Reassign the bat command after installation
    BAT=$(bat_cmd)
}

# Run initial setup
initial_setup



if [ -z "$ZSH_VERSION" ] && [ "$SHELL" = "/bin/zsh" ]; then
    directory stack
    setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
    cd_track() {
        if [ "$#" -eq 0 ]; then
            pushd "$HOME" >/dev/null
        else
            pushd "$*" >/dev/null
        fi
    }

    # Navigate back n directories
    cd_back() {
        num_dirs=${1:-1}
        count=0

        # If stack is empty, fall back to cd -
        if [ "$(dirs -p | wc -l)" -eq 0 ]; then
            cd - >/dev/null
            echo "→ $PWD"
            return
        fi

        # Otherwise pop from directory stack
        while [ "$count" -lt "$num_dirs" ]; do
            if [ "$(dirs -p | wc -l)" -gt 0 ]; then
                popd >/dev/null
                echo "→ $PWD"
            else
                cd - >/dev/null
                echo "→ $PWD"
                break
            fi
            count=$(expr "$count" + 1)
        done
    }

    alias cd='cd_track'

    # Quick navigation aliases
    alias b='cd_back 1'
    alias bb='cd_back 2'
    alias bbb='cd_back 3'
fi

uvlinkcommand() {
    # Remove existing .venv symlink or directory
    rm -rf .venv

    # Deactivate any active virtual environment
    deactivate 2>/dev/null

    # Function to search for virtual environment directories in parent dirs
    find_virtualenv() {
        local dir="$PWD"
        while [ "$dir" != "/" ]; do
            if [ -d "$dir/.venv" ] || [ -d "$dir/venv" ] || [ -d "$dir/env" ]; then
                echo "$dir/.venv"
                return 0
            fi
            dir=$(dirname "$dir")
        done
        return 1
    }

    # Locate the virtual environment directory
    env_dir=$(find_virtualenv)

    if [ -n "$env_dir" ]; then
        # Create a symbolic link to the virtual environment in the current directory
        ln -sfn "$env_dir" "$(pwd)/.venv"
        echo "Linked .venv to $env_dir"
        activate
    else
        echo "No virtual environment found in parent directories."
        return 1
    fi
}
uvunlink() {
    if [ -L ".venv" ]; then
        rm -f ".venv"
        echo "Unlinked .venv directory."
    else
        echo "No symbolic link found."
    fi
}
deletevenv() {
    if [ -d ".venv" ]; then
        echo "Are you sure you want to delete the .venv directory? (y/n): \c"
        read -r confirm
        if [ "$confirm" = "y" ]; then
            echo "Deleting .venv directory..."
            rm -rf .venv && rm -rf .python-version
        else
            echo "Deletion of .venv directory canceled."
        fi
    elif [ -d "venv" ]; then
        echo "Are you sure you want to delete the venv directory? (y/n): \c"
        read -r confirm
        if [ "$confirm" = "y" ]; then
            echo "Deleting venv directory..."
            rm -rf venv && rm -rf .python-version
        else
            echo "Deletion of venv directory canceled."
        fi
    else
        echo "No virtual environment found."
    fi
}
deactivate() {
    DEACTIVATED=0
    if [ -n "$VIRTUAL_ENV" ]; then
        deactivate
        DEACTIVATED=1
    fi
    if [ -n "$CONDA_DEFAULT_ENV" ]; then
        conda deactivate
        DEACTIVATED=1
    fi
    if [ "$DEACTIVATED" -eq 0 ]; then
        echo "No virtual environment found."
    fi
}
activate() {
    if [ -d ".venv" ]; then
        . .venv/bin/activate
    elif [ -d "venv" ]; then
        . venv/bin/activate
    elif [ -d "env" ]; then
        . env/bin/activate
    else
        if [ -z "$1" ]; then
            echo "Installing default Python 3.11. Add a Python version (e.g., 3.11) to create a different environment."
            set -- "3.11"
        fi
        echo "Creating a new virtual environment with Python $1..."
        uv venv --seed --python="$1" && . ".venv/bin/activate" && uv python pin "$(which python)"
        if uv run --no-project which python > /dev/null 2>&1; then
            echo "Virtual environment created and activated."
        else
            echo "Failed to find a valid interpreter."
        fi
    fi
}
alias a="activate"
alias d="deactivate"
alias pylink="uvlinkcommand"
alias unlink="uvunlink"
alias dv="deletevenv"

alias man='man_command' # Pretty print
alias h='help_command' # Pretty print help
alias becho='bat_echo' # Pretty print with bat
alias pc='pyclean -e "**/*.pyc" --yes . && pyclean -e "**/__pycache__" --yes .' # Alias for cleaning pyc files

export BAT
export help
export becho
export pc

export MB_BASELIB="active"


. "$MB_WS/.mbnix/utils/search.sh"
. "$MB_WS/.mbnix/utils/tree.sh"

if [ -f "$MB_WS/.mbnix/utils/git.sh" ] && [ -z "$MB_GITLIB" ]; then
. "$MB_WS/.mbnix/utils/git.sh"
fi