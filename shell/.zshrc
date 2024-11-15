# ================================
# Ensure zsh
# ================================
ensure_zsh() {
    install_util "zsh"
    if [ -z "$ZSH_VERSION" ]; then
        exec zsh -c "source $0 $@"
        return 0
    fi
    if [ -z "$MB_WS" ] || { [ -n "$install-mbnix_INSTALLING" ] && [ -z "$install-mbnix_INSTALLED" ]; }; then
        echo "You need to install mbnix first:\n curl -L https://raw.githubusercontent.com/mbodiai/mbnix/main/install-mbnix.sh | sh"
        return 0
    fi
}

# ================================
# Source setup-mbnix.sh
# ================================
setup_mbnix() {
    if ! [ -z "$MB_WS" ]; then
       . "$MB_WS/shell/setup-mbnix.sh"
    elif ! [ -f "./shell/setup-mbnix.sh" ]; then
        echo "MB_WS not set and shell/setup-mbnix.sh not found in $PWD/shell. You may need to run this script (shell/.zshrc) from the mbnix workspace."
    else
        . "./shell/setup-mbnix.sh"
    fi
}
# ================================
# Install utility
# ================================
install_util() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "$1 is not installed. Installing..."
        if [ "$(uname)" = "Linux" ]; then
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y "$1"
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y "$1"
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -Syu "$1"
            else
                echo "Package manager not supported. Please install $1 manually."
                exit 0
            fi
        elif [ "$(uname)" = "Darwin" ]; then
            if command -v brew >/dev/null 2>&1; then
                brew install "$1"
            else
                echo "Homebrew is not installed. Please install Homebrew and then install $1."
                exit 0
            fi
        else
            echo "Operating system not supported. Please install $1 manually."
            exit 0
        fi
    fi
}
# ================================
__mb_prompt() {
    local user_host="${USER}@${MB_PROMPT:-mbodi}"
    local cwd="${PWD/#$HOME/~}"
    local repo=""
    local git_branch=""
    local repo_branch=""
    local nix_shell=""

    # Check if inside a Git repository and get the branch name
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        git_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

        # Get the remote origin URL and extract the repo name
        git_remote=$(git config --get remote.origin.url)
        if [ -n "$git_remote" ]; then
            repo="${git_remote##*/}"
            repo="${repo%.git}" # Remove .git suffix if present
            repo_branch="${repo}:${git_branch}"
        fi
    fi

    # Check if in a Nix shell
    if [ -n "$IN_NIX_SHELL" ]; then
        nix_shell="(${MB_PROMPT})"
    fi

    # Construct the prompt
    if [ -n "$repo_branch" ]; then
        echo "${user_host}${nix_shell}(${repo_branch})${cwd} %"
    else
        echo "${user_host}${cwd} %"
    fi
}

# ================================
# Enable Prompt Substitution
# ================================
if [ -n "$ZSH_VERSION" ]; then
    setopt PROMPT_SUBST
fi
__mb_prompt
echo $PS1
echo $(__mb_prompt)

# ================================
# Configure PS1 with Color Variables and Prompt Function
# ================================
export PS1="%n@$(__mb_prompt) %# "
# ================================
# Setup prompt
# ================================
# if [ -z "$MB_PROMPT" ]; then
#     export MB_PROMPT="mbodi"
# fi
# __mb_prompt() {
#     local git_branch=""
#     local git_remote=""
#     local repo=""
#     local repo_branch=""
#     local nix_shell=""

#     # Check if inside a Git repository and get the branch name
#     if git rev-parse --is-inside-work-tree &>/dev/null; then
#         git_branch=$(git symbolic-ref --short HEAD 2>/dev/null)

#         # Get the remote origin URL and extract the repo name
#         git_remote=$(git config --get remote.origin.url)
#         if ! [ -z "$git_remote" ]; then
#             repo="${git_remote##*/}"
#             repo="${repo%.git}" # Remove .git suffix if present
#             repo_branch="${repo}:${git_branch}"
#         fi
#     fi

#     # Check if in a Nix shell
#     if [ -n "$IN_NIX_SHELL" ]; then
#         nix_shell="${MB_COLOR}$MB_PROMPT${RESET}"
#     fi
#     echo $nix_shell
#     return 0
#     # Display format: mb[repo:branch] or repo:branch based on nix shell status
#     if ! [ -z "$repo_branch" ]; then
#         if ! [ -z "$nix_shell" ]; then
#             echo "${nix_shell}(${repo_branch})${RESET}"
#         else
#             echo "(${repo_branch})${RESET}"
#         fi
#     fi
# }
# __mb_prompt
# # Check if running in zsh before using setopt
# if [ -n "$ZSH_VERSION" ]; then
#     setopt PROMPT_SUBST
# fi
# export PS1=$'%{\033[01;36m%}%n@%\:'"$(__mb_prompt)"$'%{\033[01;34m%}%~%{\033[0m%} %# '

# ================================
# Define the __mb_prompt Function
# ================================
# if [ -z "$MB_PROMPT" ]; then
#     export MB_PROMPT="mbodi"
# fi

# __mb_prompt() {
#     local user_host="${USER}@${MB_PROMPT:-mbodi}"
#     local cwd="${PWD/#$HOME/~}"
#     local repo=""
#     local git_branch=""
#     local repo_branch=""
#     local nix_shell=""

#     if git rev-parse --is-inside-work-tree &>/dev/null; then
#         repo=$(git rev-parse --show-toplevel 2>/dev/null)
#         git_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
#         repo="${repo##*/}" # Extract repo name
#         repo_branch="${repo}:${git_branch}"
#     fi

#     if [ -n "$IN_NIX_SHELL" ]; then
#         nix_shell="${MB_PROMPT}"
#     fi

#     if [ -n "$repo_branch" ]; then
#         if [ -n "$nix_shell" ]; then
#             echo "${user_host}(${repo_branch})${cwd} %"
#         else
#             echo "${user_host}(${repo_branch})${cwd} %"
#         fi
#     else
#         echo "${user_host}${cwd} %"
#     fi
# }


# ================================
# Configure PS1 with Color Variables and Prompt Function
# ================================
# export PS1="$(__mb_prompt)"
# export PS1=$'%{\033[01;36m%}%n@%\:'"$(__mb_prompt)"$'%{\033[01;34m%}%~%{\033[0m%} %# '
# ================================

ensure_zsh
setup_mbnix
install_util "git"
git config --global submodule.recurse true


# ================================
# Additional Configurations
# ================================
export TERM=xterm-256color
export CLICOLOR=1
# Basic zstyle configuration for completion
zstyle ':completion:*' completer _expand _complete _ignored _match _correct _approximate
zstyle ':completion:*' completions 1
zstyle ':completion:*' glob 1
zstyle ':completion:*' max-errors 2
zstyle ':completion:*' substitute 1


HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Enable autosuggestions if installed
if [[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    . ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
else
    # Fallback to using the default autosuggestions plugin
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    . ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

alias ls='ls -G --color'               # Colorized ls output
alias ll='ls -alF'             # Long format listing
alias la='ls -A'               # All files except . and ..
alias l='ls -CF'               # Classify files with file type indicator
alias grep='grep --color=auto' # Colorize grep output

[ -f ~/.fzf.zsh ] && source ~/corp/.fzf.zsh

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
export list_aliases
alias rs=". $MB_WS/shell/.zshrc"


