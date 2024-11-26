#!/bin/sh
if [ -n "$MB_SEARCH" ]; then
    echo "search already sourced. Run 'unset MB_SEARCH' to reload."
    return
fi
export MB_SEARCH="sourced"

fzf_path_completion() {
    pyclean -e "**/*.pyc" --yes . && pyclean -e "**/__pycache__" --yes .
    # Capture the selected path using fzf
    selected_path=$(find . -type f | fzf --height 40% --layout=reverse --border --select-1 --exit-0)
    cd  "${selected_path}" || return
}



fzf_history_completion() {
    selected_history=$(history | fzf --height 40% --layout=reverse --border --tac --query="$1" --select-1 --exit-0 | sed 's/^[ ]*[0-9]*[ ]*//')
    if [ -n "$selected_history"  ]; then
        echo "$selected_history"
    fi
}

# Fuzzy find a file in the current directory
fzf_file_search() {
    file=$(fzf --preview "$BAT --style=numbers --color=always {} | head -500")
    if [ -n "$file" ]; then
        if [ -d "$file" ]; then
            cd "$file" || return
    
            ${EDITOR:-code} "$file"
        fi
    fi
}


fzf_cd() {
    selected_path=$(find . -type d | fzf --height 40% --layout=reverse --border --select-1 --exit-0)
    if [ -n "$selected_path" ]; then
        cd "$selected_path" || return
    fi
}

rg_fzf() {
    rg --line-number --no-heading '' |
        fzf --delimiter ':' --nth 3.. \
            --preview 'file={1}; line={2}; [ -n "$line" ] && [ "$line" -eq "$line" ] 2>/dev/null && $BAT --style=numbers --color=always --theme=1337 --highlight-line $line "$file" | sed -n "$((line > 5 ? line - 5 : 1)),$((line + 5))p"' \
            --bind "enter:execute(code -g {1}:{2})"
}


fzf_search_replace() {
    echo "Enter search pattern:"
    read -r search_pattern

    # Use ripgrep to find all occurrences and let the user select multiple files with fzf
    files=$(rg --files-with-matches "$search_pattern" | fzf --multi --preview "$BAT --style=numbers --color=always --theme=1337 --line-range {2}-5:{2}+5 {}")

    # Check if any files were selected
    if [ -n "$files" ]; then
        echo "You selected the following files:"
        echo "$files"

        echo "Enter replacement text:"
        read -r replacement_text

        echo "Replace all instances of '$search_pattern' with '$replacement_text' in these files? [y/N]"
        confirmation=$(read -r confirmation)
        case "$confirmation" in
            [yY]) 
                    ;;
        *)
            echo "Replacement canceled."
            return
            ;;
        esac
        echo "$files" | tr '\n' '\0' | xargs -0 -I{} sed -i "s/$search_pattern/$replacement_text/g" {}
        echo "Replacement completed."

        echo "Replacement canceled."
        fi
}
alias fh='fzf_history_completion' # Fuzzy history completion
alias f="rg_fzf" # Fuzzy search in files
alias c='fzf_cd' # Fuzzy cd
alias ff='fzf_file_search' # Fuzzy file search
alias sr='fzf_search_replace' # Fuzzy search and replace