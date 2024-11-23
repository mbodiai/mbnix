#! /bin/zsh

if [ -z "$MB_WS" ]; then
    echo "MB_WS is not set. Setting to $HOME/mbnix."
    MB_WS="$HOME/mbnix"
fi

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

if [ -f ~/.zfunc/zsh-syntax-highlighting ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zfunc/zsh-syntax-highlighting

fi
. ~/.zfunc/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Enable autosuggestions if installed
if [[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    . ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
else
    # Fallback to using the default autosuggestions plugin
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    . ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fi



