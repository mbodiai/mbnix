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
        man "$@" | batcat --paging=always --language=bash --color=always
}

# Function to display help messages prettily
help() {
    "$@" --help | batcat --language=bash --color=always --theme=1337 -
}

# Helper function to determine the appropriate bat command
bat_cmd() {
    if command -v bat >/dev/null 2>&1; then
        echo "bat"
    elif command -v batcat >/dev/null 2>&1; then
        echo "batcat"
    else
        echo ""
    fi
}

# Assign the bat command once
BAT=$(bat_cmd)

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
    if ! $(which "$cmd" >/dev/null 2>&1); then
        printf "Dependency '%s' is not installed.\n" "$cmd"
        response=${response:-y}
        if [[ "$response" =~ ^(yes|y| ) || -z "$response" ]]; then
            install_dependency "$cmd" "$pkg"
        else
            printf "Cannot proceed without '%s'. Exiting.\n" "$cmd" --force
        fi
    fi
}

install_dependency() {
    local cmd="$1"
    local pkg="$2"
    
    # Check if already installed via pipx
    if pipx list | grep -q "$pkg"; then
        printf "Installing '%s' using pipx...\n" "$pkg"
        pipx install "$pkg" --force
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew >/dev/null 2>&1; then
            printf "Homebrew is not installed. Please install it from https://brew.sh/ and re-run the script.\n"
            return 1
        fi
        printf "Installing '%s' using Homebrew...\n" "$pkg"
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
            pipx install "$pkg"
        fi
    fi
}


# Alias for cleaning pyc files
alias pc='pyclean -e "**/*.pyc" --yes . && pyclean -e "**/__pycache__" --yes .'


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
        echo "Searching for term '$1' in files matching ${FILE_TYPES}..."
        rg --files-with-matches "$1" --glob '*.py' --glob '*.sh' --glob '*.md' --glob '*.toml' \
            --ignore-file <(echo '__pycache__\n*.pyc\n*.pyo') | grep -E '\.(py|sh|md|toml)$' | while read -r file; do
            if [[ "$printed_lines" -ge "$FILE_LINES" ]]; then
                break
            fi
            echo "File: $file"
            batcat --line-range=1:5 "$file" || echo "Error displaying file: $file"
            printed_lines=$((printed_lines + 5))
            echo
        done || echo "No matches found for term '$1'."
    fi
}

tgit() {
    pc
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

fzf_history_completion() {
    local selected_history
    selected_history=$(history | fzf --height 40% --layout=reverse --border --tac --query="$1" --select-1 --exit-0 | sed 's/^[ ]*[0-9]*[ ]*//')
    if [[ -n $selected_history ]]; then
        echo -n "$selected_history"
    fi
}
alias a="activate"
alias m="man_command"
alias h="help"
alias t="treecmd"
alias ts="tsearch"
alias tg="tgit"

# FZF Path Completion
fzf_path_completion() {
    pyclean -e "**/*.pyc" --yes . && pyclean -e "**/__pycache__" --yes .
    # Capture the selected path using fzf
    local selected_path=$(find . -type f | fzf --height 40% --layout=reverse --border --select-1 --exit-0)
}

alias p='fzf_path_completion'
# FZF Directory Completion

fzf_history_completion() {
    local selected_history
    selected_history=$(history | fzf --height 40% --layout=reverse --border --tac --query="$1" --select-1 --exit-0 | sed 's/^[ ]*[0-9]*[ ]*//')
    if [[ -n $selected_history ]]; then
        echo -n "$selected_history"
    fi
}

alias hist='fzf_history_completion'

# Fuzzy find a file in the current directory
fzf-file-search() {
    local file
    file=$(fzf --preview 'batcat --style=numbers --color=always {} | head -500')
    if [[ -n $file ]]; then
        if [[ -d $file ]]; then
            cd "$file"
        else
            ${EDITOR:-code} "$file"
        fi
    fi
}

# Bind ff as an alias for the fuzzy file search function
alias ff='fzf-file-search'

fzf-cd() {
    local selected_path
    selected_path=$(find . -type d | fzf --height 40% --layout=reverse --border --select-1 --exit-0)
    if [[ -n $selected_path ]]; then
        cd "$selected_path" || return
    fi
}
alias c='fzf-cd'
rg-fzf() {
    rg --line-number --no-heading '' |
        fzf --delimiter ':' --nth 3.. \
            --preview 'file={1}; line={2}; [ -n "$line" ] && [ "$line" -eq "$line" ] 2>/dev/null && bat --style=numbers --color=always --theme=1337 --highlight-line $line "$file" | sed -n "$((line > 5 ? line - 5 : 1)),$((line + 5))p"' \
            --bind "enter:execute(code -g {1}:{2})"
}
alias f="rg-fzf"

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
alias d="deactivate"
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

alias dv='deletevenv'
cd_back() {
    # Keep track of stack to go back n directories
    if [ -n "$OLDPWD" ]; then
        cd "$OLDPWD" || return
    else
        cd ~ || return 
    fi
}
alias b='cd -'
alias bb='cd_back && cd_back'
alias bbb='cd_back && cd_back && cd_back'

# Ensure Nix environment is loaded each time
if [ -e /etc/profile.d/nix.sh ]; then
    . /etc/profile.d/nix.sh
fi



# tmp_clipboard_file location (example of other configuration)
tmp_clipboard_file="$MB_DIR/tmp/clipboard.txt"

alias ls='ls -G -C'               # Colorized ls output
alias ll='ls -alF'             # Long format listing
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

alias gdc='git diff --compact-summary'