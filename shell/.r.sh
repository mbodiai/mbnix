# Git and Terminal Configurations
if ! "$HOME/.local/bin" in *$PATH*; then
    echo "Adding $HOME/.local/bin to PATH"
    export PATH="$HOME/.local/bin:$PATH"
fi
bat_cmd() {
    if command -v bat >/dev/null; then
        echo "bat"
    elif command -v batcat >/dev/null; then
        echo "batcat"
    else
        ensure_dependency "bat" "batcat"
        if command -v batcat >/dev/null; then
            echo "batcat"
        else
            echo "cat"
        fi
    fi
}
# Assign the bat command once
export BAT=$(bat_cmd)
git config --global submodule.recurse true

# Alias to deactivate the current virtual environment
if [ -n "$VIRTUAL_ENV" ]; then
    deactivate
fi
if [ -v $MB_WS ]; then

    MB_WS="$HOME/mbnix"
    echo "No workspace directory found. Setting MB_WS to $MB_WS"
fi



# Nix setup
# if ! command -v nix &>/dev/null; then
#     echo "Nix not found, installing..."
#     sh <(curl -L https://nixos.org/nix/install) --daemon
#     . /etc/profile.d/nix.sh  # Load Nix immediately after install
# fi

# Ensure Nix environment is loaded each time
if [ -e /etc/profile.d/nix.sh ]; then
    . /etc/profile.d/nix.sh
fi


export NIX_CONF_DIR="$MB_WS"
if [ -f "$NIX_CONF_DIR/nix.conf" ]; then
    echo "experimental-features = nix-command flakes" >> "$NIX_CONF_DIR/nix.conf"
fi
# tmp_clipboard_file location (example of other configuration)
tmp_clipboard_file="$MB_WS/.tmp/clipboard.txt"
mkdir -p "$MB_WS/.tmp" && touch "$tmp_clipboard_file"
# Install Rust if not already installed
if ! [ -x "$(command -v rustup)" ]; then

    echo "Rust not found, installing..."
    curl -LsSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    export PATH="$HOME/.cargo/bin:$PATH"
    . "$HOME/.cargo/env"  # Load Rust immediately after install

else
    echo "Rust installed at $(which rustup)"
fi
if [ -f "$HOME/.cargo/env" ]; then
. "$HOME/.cargo/env"  
else
    echo "Warning: Rust environment not found. Searched: $HOME/.cargo/env"
fi

# Install UV if not present
if ! command -v uv &>/dev/null; then
    echo "Installing UV..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    echo "UV installed at $(which uv)"
fi

# Install GitHub CLI extension for code searching if GitHub CLI is present
if command -v gh && ! gh extension list | grep -q "gh-find-code"; then
    echo "Installing GitHub CLI extension 'gh-find-code'..."
    gh extension install LangLangBart/gh-find-code
fi

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
alias d="deactivate" # Deactivate the virtual environment

cd_back() {
    # Keep track of stack to go back n directories
    if [ -n "$OLDPWD" ]; then
        cd "$OLDPWD" || return
    else
        cd ~ || return 
    fi
}


record_terminal() {
    # Ensure the directories for pipx and bin are set up
    mkdir -p ~/.local/pipx/venvs
    mkdir -p ~/.local/bin
    export PIPX_MB_WS="$MB_WS/.local/pipx"
    export PIPX_BIN_DIR="$MB_WS/.local/bin"
    export PATH="$PIPX_BIN_DIR:$PATH"

    # Set a default output path if none provided
    local output_file="${1:-$MB_WS/termtosvg_output.svg}"

    # Check if 'termtosvg' exists using 'type'
    if type termtosvg > /dev/null 2>&1; then
        termtosvg "$output_file"
    else
        # Clone the repository only if needed
        [ ! -d "$MB_WS/.termtosvg" ] && git clone https://github.com/nbedos/termtosvg.git "$MB_WS/.termtosvg"
        
        cd "$MB_WS/.termtosvg" || return

        # Check if 'pipx' is installed; install if missing
        if ! type pipx > /dev/null 2>&1; then
            python3 -m pip install --user pipx
        pipx ensurepath
        fi

        # Use pipx to install termtosvg
        pipx install .
        
        cd - || return
        termtosvg "$output_file"
    fi
}
uvlinkcommand() {
    rm -rf .venv
    deactivate
    activate &>/dev/null
    if which python &>/dev/null; then
        ln -sfn "$env_path" "$(pwd)/.venv"
        uv sync
        echo "Virtual environment linked $(pwd)/.venv -> $env_path"
    else
        cd ..
        activate
        cd -
        if which python &>/dev/null; then
            env_path=$(dirname $(dirname $(which python)))
            ln -sfn "$env_path" "$(pwd)/.venv"
            uv sync
            echo "Virtual environment linked $(pwd)/.venv -> $env_path"
        else
            echo "No interpreter found."
        fi
    fi
}
uvcomplete() {

alias uvlink="uvlinkcommand" # Link the virtual environment
# Determine the current shell and set the appropriate value for uv generate-shell-completion
    case "$0" in
*/bash)
        source "$(uv generate-shell-completion bash)"
    ;;
*/zsh)
        source "$(uv generate-shell-completion zsh)"
    ;;
*/fish)
        source "$(uv generate-shell-completion fish)"
    ;;
*/elvish)
        source "$(uv generate-shell-completion elvish)"
    ;;
*/nushell)
    eval "$(uv generate-shell-completion nushell)"
    ;;
*/powershell)
        source "$(uv generate-shell-completion powershell)"
    ;;
*)
    echo "Unsupported shell: $0"
    ;;
esac
}

# export PATH="/opt/MB_WS/brew/opt/python@3.11/libexec/bin:$PATH"

# Function to delete the virtual environment
dd() {
    if [ -d ".venv" ]; then
        echo "Deleting .venv directory..."
        rm -rf .venv
    elif [ -d "venv" ]; then
        echo "Deleting venv directory..."
        rm -rf venv
    else
        echo "No virtual environment found."
    fi
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
        man "$@" | $BAT --paging=always --language=bash --color=always
}

# Function to display help messages prettily
help() {
    "$@" --help | $BAT --language=bash --color=always --theme=1337 -
}



# Helper function to display timestamps if enabled
get_mod_time() {
    local file="$1"
    if [ "$display_timestamps" = true ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            stat -f "Modified: %Sm" -t "%Y-%m-%d %H:%M:%S" "$file"
        else
            # Assume Linux
            stat --format="Modified: %y" "$file"
        fi
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
    local cmd="$1"
    local pkg="$2"
    if ! command -v "$cmd"; then
        printf "Dependency '%s' is not installed.\n" "$cmd"s
        if [[ "$response" =~ ^(yes|y| ) || -z "$response" ]]; then
            install_dependency "$cmd" "$pkg"
        else
            printf "Skipping installation of '%s'.\n" "$cmd"
        fi
    fi
}

install_dependency() {
    local cmd="$1"
    local pkg="$2"
    
    # Check if already installed via pipx
    if pipx list | grep -q "$pkg" >/dev/null 2>&1; then
        printf "Installing '%s' using pipx...\n" "$pkg"
        pipx install "$pkg" --force
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew >/dev/null 2>&1; then
            printf "MB_WSbrew is not installed. Please install it from https://brew.sh/ and re-run the script.\n"
            return 1
        fi
        printf "Installing '%s' using MB_WSbrew...\n" "$pkg"
        brew install "$pkg"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && \
            sudo apt-get install -y "$pkg" || pipx install "$pkg"
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y "$pkg" || pipx install "$pkg"
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf install -y "$pkg" || pipx install "$pkg"
        else
            printf "No supported package manager found (apt, yum, dnf). Installing '%s' with pipx instead.\n" "$pkg"
        fi
    fi
}

# Initial setup: Check and install dependencies
initial_setup() {
    # List of dependencies: command -> package name
    dependencies=(
        "tree:tree"
        "rg:ripgrep"
        "bat:bat"
        "batcat:bat"
        "git:git"
        "pyclean:pyclean" # Adjust package name if different
        "find:find"
    )

    for dep in "${dependencies[@]}"; do
        cmd="${dep%%:*}"
        pkg="${dep##*:}"
        
        # Special handling: check for 'bat' or 'batcat'
        if [[ "$cmd" == "batcat" ]]; then
            continue
        fi

        if ! command -v "$cmd" >/dev/null 2>&1; then
            # For 'bat', check 'bat' or 'batcat'
            if [[ "$cmd" == "bat" ]]; then
                if ! command -v bat >/dev/null 2>&1 && ! command -v batcat >/dev/null 2>&1; then
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

# Function t: Lists the directory tree or searches file contents
treecmd() {
    thelp() {
        printf "Usage: t [-t|--timestamps] [DIRECTORY] [DEPTH] [TERM] [--help, -h]\nOptions:\n    -t, --timestamps    Display the tree with the modification time of the files.\n    DIRECTORY            The directory to display the tree for. Defaults to the current directory.\n    DEPTH                The depth of the tree to display. Defaults to 2.\n    TERM                 A search term to look for within the contents of the files in the tree.\n    --help, -h           Show this help message.\n" | ${BAT:-cat} -
    }

    # Ensure dependencies are installed
    ensure_dependency "tree" "tree"

    # Set defaults
    display_timestamps=false
            depth=2
    term=""

    # Parse options
    while [[ "$1" == -* ]]; do
        case "$1" in
            -t|--timestamps)
                display_timestamps=true
                shift
                ;;
            --help|-h)
        thelp
                return
                ;;
            *)
                printf "Unknown option: %s\n" "$1" | ${BAT:-cat} -
                thelp
                return 1
                ;;
        esac
    done

    # Assign remaining arguments
    DIRECTORY="${1:-.}"
    DEPTH="${2:-$depth}"
    TERM="${3:-}"

    if [ -d "$DIRECTORY" ]; then
        echo "Displaying tree for directory '$DIRECTORY' with depth $DEPTH:"
        if [ "$display_timestamps" = true ]; then
            tree -I '__pycache__|*.pyc|*.pyo' -L "$DEPTH" --dirsfirst --timefmt="%Y-%m-%d %H:%M:%S" -t -C "$DIRECTORY"
        else
            tree -I '__pycache__|*.pyc|*.pyo' -L "$DEPTH" --dirsfirst -t -C "$DIRECTORY"
        fi
    elif [[ "$DIRECTORY" =~ ^[0-9]+$ ]]; then
        # If DIRECTORY is actually DEPTH
        DEPTH="$DIRECTORY"
        echo "Displaying tree with depth $DEPTH:"
        if [ "$display_timestamps" = true ]; then
            tree -I '__pycache__|*.pyc|*.pyo' -L "$DEPTH" --dirsfirst --timefmt="%Y-%m-%d %H:%M:%S" -t -C
    else
            tree -I '__pycache__|*.pyc|*.pyo' -L "$DEPTH" --dirsfirst -t -C
        fi
    elif [ -z "$DIRECTORY" ]; then
        thelp
    else
        # Handle TERM search
        # Ensure dependencies are installed
        ensure_dependency "rg" "ripgrep"

        echo "Searching for term '$DIRECTORY' within the contents of the files in the tree..."
        rg --with-filename -C 1 "$DIRECTORY" || printf "No matches found for term '%s'.\n" "$DIRECTORY" | ${BAT:-cat} -
    fi
}

# Cleans up pyc files and searches for term in specific file types with timestamps
tsearch() {
    FILE_TYPES="*.py *.sh *.md *.toml"
    FILE_LINES=50
    printed_lines=0
    display_timestamps=false

    # Ensure dependencies are installed
    ensure_dependency "rg" "ripgrep"

    # Determine the appropriate bat command
    if [ -z "$BAT" ]; then
        echo "Note: 'bat' is not installed. Using 'cat' instead."
    fi

    # Parse options
    while [[ "$1" == -* ]]; do
        case "$1" in
            --timestamps)
                display_timestamps=true
                shift
                ;;
            --help|-h)
                printf "Usage: ts [term] [--tests] [--timestamps]\nOptions:\n    term        A search term to look for within the specified file types (${FILE_TYPES}).\n                Displays a summary of up to ${FILE_LINES} lines.\n    --tests     Include test files (files in 'tests/' directories or prefixed with 'test_').\n    --timestamps Display the modification time for each file.\n    --help, -h  Show this help message.\n" | ${BAT:-cat} -
                return
                ;;
            *)
                printf "Unknown option: %s\n" "$1" | ${BAT:-cat} -
                return 1
                ;;
        esac
    done

    # Assign remaining arguments
    TERM_SEARCH="$1"

    # Clean pyc files
    ensure_dependency "pyclean" "clean"
    pyclean -e "**/*.pyc" --yes . && pyclean -e "**/__pycache__" --yes .

    if [[ "$TERM_SEARCH" == "--tests" ]]; then
        echo "Including test files..."
        ensure_dependency "find" "find" # Usually available by default
        find . -type f \( -name "test_*.py" -o -path "*/tests/*.py" \) -not -path "*/__pycache__/*" -not -name "*.pyc" -not -name "*.pyo" | while read -r file; do
            if [[ "$printed_lines" -ge "$FILE_LINES" ]]; then
                break
            fi
            preview_file "$file" 5
        done
    elif [[ -z "$TERM_SEARCH" ]]; then
        echo "Searching for all files of specified types..."
        ensure_dependency "find" "find"
        find . -type f \( -name "*.py" -o -name "*.sh" -o -name "*.md" -o -name "*.toml" \) \
            -not -path "*/__pycache__/*" -not -name "*.pyc" -not -name "*.pyo" | while read -r file; do
            if [[ "$printed_lines" -ge "$FILE_LINES" ]]; then
                break
            fi
            preview_file "$file" 5
        done
    else
        echo "Searching for term '$TERM_SEARCH' in files matching ${FILE_TYPES}..."
        rg --files-with-matches "$TERM_SEARCH" --glob '*.py' --glob '*.sh' --glob '*.md' --glob '*.toml' \
            --ignore-file <(printf '__pycache__\n*.pyc\n*.pyo') | grep -E '\.(py|sh|md|toml)$' | while read -r file; do
            if [[ "$printed_lines" -ge "$FILE_LINES" ]]; then
                break
            fi
                preview_file "$file" 5
            done || printf "No matches found for term '%s'.\n" "$TERM_SEARCH" | ${BAT:-cat} -
    fi
}

tgit() {
    FILE_LINES=50
    printed_lines=0
    display_timestamps=false

    # Ensure dependencies are installed
    ensure_dependency "git" "git"

    # Determine the appropriate bat command
    if [ -z "$BAT" ]; then
        echo "Note: 'bat' is not installed. Using 'cat' instead."
    fi

    # Parse options
    while [[ "$1" == -* ]]; do
        case "$1" in
            --timestamps)
                display_timestamps=true
                shift
                ;;
            --help|-h)
                printf "Usage: tgit [--timestamps]\nOptions:\n    --timestamps    Display the modification time for each changed file.\n    --help, -h      Show this help message.\n" | ${BAT:-cat} -
                return
                ;;
            *)
                printf "Unknown option: %s\n" "$1" | ${BAT:-cat} -
                return 1
                ;;
        esac
    done

    # Function to handle file diffs
    handle_diff() {
        local file="$1"
        if [ "$printed_lines" -ge "$FILE_LINES" ]; then
            return
        fi
        if [ -f "$file" ]; then
            echo "File: $file"
            if [ "$display_timestamps" = true ]; then
                get_mod_time "$file"
            fi
            git diff HEAD~1 HEAD -- "$file" | if [ -n "$BAT" ]; then
                $BAT --paging=never
            else
                cat
            fi || echo "Error displaying diff for file: $file"
            printed_lines=$((printed_lines + 5))
            echo
        fi
    }

    echo "Files changed in the last commit:"
    git diff --name-only HEAD~1 HEAD | while read -r file; do
        handle_diff "$file"
    done

    echo "Files with uncommitted changes:"
    git diff --name-only | while read -r file; do
        handle_diff "$file"
    done
}



# FZF Path Completion
fzf_path_completion() {
    pyclean -e "**/*.pyc" --yes . && pyclean -e "**/__pycache__" --yes .
    # Capture the selected path using fzf
    local selected_path=$(find . -type f | fzf --height 40% --layout=reverse --border --select-1 --exit-0)
}




activate() {
    if [ -d ".venv" ]; then
        source .venv/bin/activate
    elif [ -d "venv" ]; then
        source venv/bin/activate
    elif [ -d "env" ]; then
        source env/bin/activate
    # elif which conda >/dev/null 2>&1; then
    #     if conda env list | grep -q "base"; then
    #         conda activate base
    #     else
    #         echo "No conda base environment found."
    #     fi
    else
        if [ -z "$1"]; then
            echo "Installing default python 3.11 Add a python version, e.g. 3.11, to create a different environment."
            1="3.11"
        fi
        echo "Creating a new virtual environment..."
        uv venv --seed --python="$1" && source ".venv/bin/activate" && uv python pin $(which python)
        if uv run --no-project which python &>/dev/null; then
            echo "Virtual environment created and activated."
        else
            echo "No interpreter found."
        fi

    fi
}

# FZF Path Completion
fzf_path_completion() {
    pyclean -e "**/*.pyc" --yes . && pyclean -e "**/__pycache__" --yes .
    # Capture the selected path using fzf
    local selected_path=$(find . -type f | fzf --height 40% --layout=reverse --border --select-1 --exit-0)
}

alias p='fzf_path_completion'

# FZF Directory Completion



# FZF Directory Completion

fzf_history_completion() {
    local selected_history
    selected_history=$(history | fzf --height 40% --layout=reverse --border --tac --query="$1" --select-1 --exit-0 | sed 's/^[ ]*[0-9]*[ ]*//')
    if [[ -n $selected_history ]]; then
        echo -n "$selected_history"
    fi
}


# Fuzzy find a file in the current directory
fzf-file-search() {
    local file
    file=$(fzf --preview '$BAT --style=numbers --color=always {} | head -500')
    if [[ -n $file ]]; then
        if [[ -d $file ]]; then
            cd "$file"
        else
            ${EDITOR:-code} "$file"
        fi
    fi
}



fzf-cd() {
    local selected_path
    selected_path=$(find . -type d | fzf --height 40% --layout=reverse --border --select-1 --exit-0)
    if [[ -n $selected_path ]]; then
        cd "$selected_path" || return
    fi
}

rg-fzf() {
    rg --line-number --no-heading '' |
        fzf --delimiter ':' --nth 3.. \
            --preview 'file={1}; line={2}; [ -n "$line" ] && [ "$line" -eq "$line" ] 2>/dev/null && bat --style=numbers --color=always --theme=1337 --highlight-line $line "$file" | sed -n "$((line > 5 ? line - 5 : 1)),$((line + 5))p"' \
            --bind "enter:execute(code -g {1}:{2})"
}

fzf_search_replace() {
    echo "Enter search pattern:"
    read search_pattern

    # Use ripgrep to find all occurrences and let the user select multiple files with fzf
    local files=$(rg --files-with-matches "$search_pattern" | fzf --multi --preview "bat --style=numbers --color=always --theme=1337 --line-range {2}-5:{2}+5 {}")

    # Check if any files were selected
    if [[ -n "$files" ]]; then
        echo "You selected the following files:"
        echo "$files"

        echo "Enter replacement text:"
        read replacement_text

        echo "Replace all instances of '$search_pattern' with '$replacement_text' in these files? [y/N]"
        read confirmation
        if [[ "$confirmation" =~ ^[yY]$ ]]; then
            echo "$files" | tr '\n' '\0' | xargs -0 -I{} sed -i "s/$search_pattern/$replacement_text/g" {}
            echo "Replacement completed."
        else
            echo "Replacement canceled."
        fi
    else
        echo "No files selected."
    fi
}




# Function to clean up a submodule and push it to a temporary branch
git_submodule_clean() {
    if [ -z "$1" ]; then
        echo "Usage: git_submodule_clean <submodule-path>"
        return 1
    fi

    submodule_path="$1"

    # Ensure the submodule exists
    if [ ! -d "$submodule_path" ]; then
        echo "Error: Submodule path '$submodule_path' does not exist."
        return 1
    fi

    # Get the submodule URL from .gitmodules
    submodule_url=$(git config --file .gitmodules --get submodule."$submodule_path".url)
    if [ -z "$submodule_url" ]; then
        echo "Error: Could not find URL for submodule '$submodule_path'."
        return 1
    fi
    echo "Submodule URL: $submodule_url"

    # Create a temporary branch to save the submodule
    echo "Pushing submodule '$submodule_path' to a temporary branch..."
    (cd "$submodule_path" && git checkout -b temp_submodule_branch && git push origin temp_submodule_branch)

    # Deinitialize the submodule
    echo "Deinitializing submodule '$submodule_path'..."
    git submodule deinit -f "$submodule_path"

    # Remove the submodule from the index and the .gitmodules file
    echo "Removing submodule '$submodule_path' from the index and .gitmodules..."
    git rm -f "$submodule_path"

    # Commit the changes to the main repo
    git commit -m "Removed submodule $submodule_path and saved it to a temp branch."

    # Remove the submodule entry from the .git/modules folder
    echo "Removing submodule cache from .git/modules..."
    rm -rf ".git/modules/$submodule_path"

    # Remove the submodule's working directory
    echo "Deleting submodule directory '$submodule_path'..."
    rm -rf "$submodule_path"

    # Save the submodule URL to a temporary file for reuse
    echo "Saving submodule URL..."
    echo "$submodule_url" >/tmp/"$submodule_path"_url.txt

    echo "Submodule '$submodule_path' cleaned successfully and saved to temp branch."
}


alias gld='git_list_diffs_last_commit'
deletevenv() {
    if [ -d ".venv" ]; then
        echo "Are you sure you want to delete the .venv directory? (y/n): \c"
        read confirm
        if [ "$confirm" = "y" ]; then
            echo "Deleting .venv directory..."
            rm -rf .venv && rm -rf .python-version
        else
            echo "Deletion of .venv directory canceled."
        fi
    elif [ -d "venv" ]; then
        echo "Are you sure you want to delete the venv directory? (y/n): \c"
        read confirm
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


addmypy() {
    if echo $VIRTUAL_ENV | grep -q "venv"; then
        echo "Adding mypy to the virtual environment..."
        uv python pin $(which python)
    else
        echo "No virtual environment found."
    fi
}

alias ls='ls -G --color'               # Colorized ls output
alias ll='ls -alF --color'             # Long format listing
alias la='ls -A'               # All files except . and ..
alias l='ls -CF'               # Classify files with file type indicator
alias ccat='pygmentize -g'     # Colorized cat output
alias grep='grep --color=auto' # Colorized grep output
alias diff='colordiff'         # Colorized diff output
alias cp='cp -i'               # Prompt before overwriting files
alias mv='mv -i'               # Prompt before overwriting files
alias rm='rm -i'               # Prompt before removing files
alias mkdir='mkdir -p'         # Automatically create parent directories
alias df='df -h'               # Human-readable disk usage
alias du='du -h'               # Human-readable directory sizes
alias free='free -h'           # Human-readable memory usage
alias ps='ps aux'              # Show all processes
alias top='htop'               # Improved top command
alias wget='wget -c'           # Continue partial downloads
alias uw='uv run --no-project which python'
alias ur='uv run --no-project'
alias uvb='uv build && uv run twine upload dist/* -u __token__ -p  "$(echo $PYPI_TOKEN)" --non-interactive'
alias add='uv add --no-config'
alias uvp='uv python pin $(which python)'
alias nixd='nix develop --extra-experimental-features nix-command --extra-experimental-features flakes'
alias pc='pyclean -e "**/*.pyc" --yes . && pyclean -e "**/__pycache__" --yes .'
alias p='fzf_path_completion'
alias p='fzf_path_completion'
alias hist='fzf_history_completion'
alias c='fzf-cd'
alias ff='fzf-file-search'
alias f="rg-fzf"

alias gs='git_search_term'
alias b='cd -'
alias bb='cd_back && cd_back'
alias bbb='cd_back && cd_back && cd_back'
 
alias a="activate" # Activate the virtual environment
alias m="man_command" # Pretty man command
alias h="help" # Pretty help command
alias t="treecmd" # List directory tree or search file contents
alias ts="tsearch" # Search for a term in specific file types
alias tg="tgit" # Display files changed in the last commit
alias gdc='git diff --compact-summary' # Display git diff in compact summary format
alias gitcliff='git-cliff' # Display git history as a changelog
alias dv='deletevenv' # Delete the virtual environment
alias gpt='git_push_temp' # Update and push each submodule to a temporary branch
alias gsc='git_submodule_clean' # Clean and push a submodule to a temporary branch
alias gsub='gsub_make' # Clean and reinitialize a submodule