#!/bin/zsh

if [ -z "$_ZSHRC_RUNNING" ]; then
    export _ZSHRC_RUNNING=0
fi

if [ $_ZSHRC_RUNNING -eq 1 ]; then
    return
fi
export _ZSHRC_RUNNING=1

# Basic zstyle configuration for completion
zstyle ':completion:*' completer _expand _complete _ignored _match _correct _approximate
zstyle ':completion:*' completions 1
zstyle ':completion:*' glob 1
zstyle ':completion:*' max-errors 2
zstyle ':completion:*' substitute 1
if [ -z $MB_WS ]; then
    export MB_WS=$(pwd)
    source $MB_WS/.zshrc
fi

HISTFILE=$MB_WS/.zsh_history
if [ -f $HOME/.zsh_history ]; then
    cat $HOME/.zsh_history >>$HISTFILE
fi
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Syntax Highlighting
if ! [ -d "$MB_WS/.zfunc/zsh-syntax-highlighting" ]; then
    mkdir -p $MB_WS/.zfunc
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $MB_WS/.zfunc/zsh-syntax-highlighting

fi
if [ -n $ZSH_SYNTAX_HIGHLIGHTING ]; then

    source $MB_WS/.zfunc/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    export ZSH_SYNTAX_HIGHLIGHTING="sourced"
fi

# Autosuggestions
if ! [ -f $MB_WS/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then

    git clone https://github.com/zsh-users/zsh-autosuggestions $MB_WS/.zsh/zsh-autosuggestions
fi
if [ -n $ZSH_AUTOSUGGESTIONS ]; then
    source $MB_WS/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
    export ZSH_AUTOSUGGESTIONS="sourced"
fi

if [ -f $MB_WS/.mbnix/setup.sh ]; then
    source $MB_WS/.mbnix/setup.sh
fi
unset _ZSHRC_RUNNING
