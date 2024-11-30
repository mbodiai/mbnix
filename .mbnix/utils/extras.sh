# ==========================================
# Copied to avoid import shell Configurations
# ==========================================
if [ -z "$_MB_SETUP_EXTRAS_RUNNING" ]; then
    export _MB_SETUP_EXTRAS_RUNNING=0
fi
if [ "$_MB_SETUP_EXTRAS_RUNNING" -eq 1 ]; then
    return
fi
export _MB_SETUP_EXTRAS_RUNNING=1
get_user_shell() {
    ps -p $$ -o comm=
}


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
        MANWIDTH=120 man "$@" | col -b | $BAT --paging=always --color=always
}

help_command() {
    "$@" --help | $BAT --color=always --theme=ansi -
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
        stat -f "Modified: %Sm" -t "%b %d, %Y" "$file" | while read -r line; do
            tfmt "$line"
        done
    else
        # Linux
        stat -c "Modified: %y" "$file" | while read -r line; do
            tfmt "$line"
        done
    fi
}
# Function to parse and format date
tfmt() {
    input_date="$1"
    formatted_date=$(date -d "$input_date" +"%b %d, %Y" 2>/dev/null || date -jf "%Y-%m-%d %H:%M:%S %z" "$input_date" +"%b %d, %Y" 2>/dev/null)
    if [ -n "$formatted_date" ]; then
        echo "$formatted_date"
    else
        echo "Invalid date format: $input_date"
    fi
}
export tfmt
# Helper function for bat preview with line limitation
preview_file() {
    file="$1"
    lines="$2"
    width=120 # Configurable width

    # File header with proper wrapping
    printf "File: %s\n" "$file" | fold -s -w "$width"
    get_mod_time "$file" | fold -s -w "$width"

    if [ -n "$BAT" ]; then
        $BAT \
            --line-range=1:"$lines" \
            --wrap=character \
            --terminal-width="$width" \
            --style=plain \
            "$file" || echo "Error displaying file: $file"
    else
        cat "$file" | fold -s -w "$width" | head -n "$lines" ||
            echo "Error displaying file: $file"
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
        elif command -v cargo >/dev/null 2>&1; then
            cargo install "$pkg"
        elif command -v pipx >/dev/null 2>&1; then
            pipx install "$pkg"
        elif command -v python -m pipx >/dev/null 2>&1; then
            python -m pipx install "$pkg"
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

install_bat() {
    if command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1; then
        return 0
    fi

    printf "Installing bat...\n"
    
    if [ "$(uname)" = "Linux" ]; then
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update
            # Correct package name for Ubuntu is 'bat'
            if sudo apt-get install -y bat; then
                # bat command gets installed as 'batcat' on Ubuntu
                mkdir -p "$HOME/.local/bin"
                ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
                export PATH="$HOME/.local/bin:$PATH"
                return 0
            fi
        fi
    fi

    # Verify installation
    if ! command -v bat >/dev/null 2>&1 && ! command -v batcat >/dev/null 2>&1; then
        printf "Failed to install bat/batcat\n" >&2
        return 1
    fi
}
# Initial setup: Check and install dependencies
initial_setup() {
    # List of dependencies: command:package
    dependencies="tree:tree rg:ripgrep bat:bat git:git pyclean:pyclean find:find uv:uv"
    echo "$dependencies" | tr ' ' '\n' | while IFS=: read -r cmd pkg; do
        case "$cmd" in
        bat)
            install_bat || echo "Please install bat manually"
            continue
            ;;
        pyclean)
            if ! command -v pyclean >/dev/null 2>&1; then
                pipx install pyclean --force
                pipx ensurepath
            fi
            ;;
        uv)
            if ! command -v uv >/dev/null 2>&1; then
                echo "Installing 'uv'..."
                curl -LsSf https://astral.sh/uv/install.sh | sh

            else
                ensure_dependency "$cmd" "$pkg"
            fi

            ;;
        *)
            if ! command -v "$cmd" >/dev/null 2>&1; then
                ensure_dependency "$cmd" "$pkg"
            fi
            ;;
        esac
    done

    # Reassign the bat command after installation
    BAT=$(bat_cmd)
}
export PATH="$HOME/.local/bin:$PATH"
# Run initial setup
initial_setup


if [ -n "$ZSH_VERSION" ] && [ "$(get_user_shell)" = "zsh" ]; then

    # Extract Zsh major and minor versions
    zsh_major=${ZSH_VERSION%%.*}
    zsh_minor=${ZSH_VERSION#*.}
    zsh_minor=${zsh_minor%%.*}

    if [ "$zsh_major" -gt 5 ] || { [ "$zsh_major" -eq 5 ] && [ "$zsh_minor" -ge 9 ]; }; then
        if [ -n "$POSIXLY_CORRECT" ]; then
            # POSIX compliant actions
            echo "Zsh version is >= 5.9 and running in POSIX mode."
            setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
            # Enhanced cd that maintains directory stack
            cd() {
                if [[ $# -eq 0 ]]; then
                    pushd "$HOME" >/dev/null
                else
                    pushd "$@" >/dev/null
                fi
            }

            # Navigate back n directories
            cd_back() {
                local n=${1:-1}

                # If stack is empty, fall back to cd -
                if [[ ${#dirstack} -eq 0 ]]; then
                    cd - >/dev/null
                    echo "→ $PWD"
                    return
                fi

                # Otherwise pop from directory stack
                for ((i = 0; i < n; i++)); do
                    if [[ ${#dirstack} -gt 0 ]]; then
                        popd >/dev/null
                        echo "→ $PWD"
                    else
                        cd - >/dev/null
                        echo "→ $PWD"
                        break
                    fi
                done
            }
            

            # Quick navigation aliases
            alias b='cd_back 1'
            alias bb='cd_back 2'
            alias bbb='cd_back 3'
            export cd
        fi
    fi
fi

# Function to search for virtual environment directories in parent dirs
find_virtualenv() {
    dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.venv" ] || [ -d "$dir/venv" ] || [ -d "$dir/env" ]; then
            echo "$dir/.venv"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}
uvlinkcommand() {
    # Remove existing .venv symlink or directory
    rm -rf .venv
    if ! which deactivate >/dev/null 2>&1 && ! env | grep -q "VIRTUAL_ENV"; then
        echo "No virtual environment found."
        return 1
    fi
    # Deactivate any active virtual environment
    deactivate 2>/dev/null
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


deactivate_cmd() {
    [ -n "$CONDA_DEFAULT_ENV" ] && conda deactivate && echo "Deactivated conda environment." && return
    [ -n "$HATCH_ENV_ACTIVE" ] && deactivate && echo "Deactivated hatch environment." && return
    [ -n "$VIRTUAL_ENV" ] && conda deactivate && echo "Deactivated virtual environment."

    if [ -n "$VIRTUAL_ENV" ]; then
        unset VIRTUAL_ENV
        unset HATCH_ENV_ACTIVE
    fi

}
activate_cmd() {
    if [ -d ".venv" ] && [ -f ".venv/bin/activate" ]; then
        echo "Activating virtual environment in .venv..."
        . .venv/bin/activate
    elif [ -d "venv" ] && [ -f "venv/bin/activate" ]; then
        echo "Activating virtual environment in venv..."
        . venv/bin/activate
    elif [ -d "env" ] && [ -f "env/bin/activate" ]; then
        echo "Activating virtual environment in env..."
        . env/bin/activate
    else
        echo "No virtual environment found in parent directories."
        env_dir=$(find_virtualenv) && [ -n "$env_dir" ] && . "$env_dir/bin/activate" && return
    
        if [ -z "$1" ]; then
            echo "Installing default Python 3.11. Add a Python version (e.g., 3.11) to create a different environment."
            set -- "3.11"
        fi
        echo "Creating a new virtual environment with Python $1..."
        uv venv --seed --python="$1" && . ".venv/bin/activate" && uv python pin "$(which python)"
        if uv run --no-project which python >/dev/null 2>&1; then
            echo "Virtual environment created and activated."
        else
            echo "Failed to find a valid interpreter."
        fi
    fi
}
# Store Conda default environment if not set
export CONDA_DEFAULT_ENV=${CONDA_DEFAULT_ENV:-"base"}


activate_last_conda_env() {
    if [ -n "$CONDA_LAST_ENV" ]; then
        echo "Activating last Conda environment: $CONDA_LAST_ENV"
        conda activate "$CONDA_LAST_ENV"
    else
        echo "Falling back to default Conda environment: $CONDA_DEFAULT_ENV"
        conda activate "$CONDA_DEFAULT_ENV"
    fi
}


alias ac='activate_last_conda_env' # Activate last Conda environment
alias a="activate_cmd"           # Activate virtual environment
alias d="deactivate_cmd"         # Deactivate virtual environment
alias pylink="uvlinkcommand" # Link to virtual environment
alias unlink="uvunlink"      # Unlink virtual environment
alias dv="deletevenv"        # Delete virtual environment

alias man='man_command'                                                              # Pretty print
alias h='help_command'                                                               # Pretty print help
alias becho='bat_echo'                                                               # Pretty print with bat
alias pc='pyclean -e "**/*.pyc" --yes . && pyclean -e "**/__pycache__/**/*" --yes .' # Clean Python files
alias help='help_command'                                                            # Pretty print help
export BAT
export becho
export pc

# =======
# Imports
# =======
. "$MB_WS/.mbnix/utils/search.sh"
. "$MB_WS/.mbnix/utils/tree.sh"
. "$MB_WS/.mbnix/utils/git.sh"
. "$MB_WS/.mbnix/utils/doctor.sh"
. "$MB_WS/.mbnix/utils/bench.sh"
. "$MB_WS/.mbnix/utils/record.sh"
. "$MB_WS/.mbnix/utils/cppaste.sh"
unset _MB_SETUP_EXTRAS_RUNNING