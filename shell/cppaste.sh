#!/usr/bin/zsh

# =============================================================================
# .r.sh - Zsh Configuration Script
# =============================================================================

# -----------------------------
# Variables to Store Command and Output
# -----------------------------
export last_command=""
export last_output=""
tmp_output_file="/tmp/last_command_output_$$.txt"

# -----------------------------
# Clipboard Utility Function
# -----------------------------
copy_to_clipboard() {
    local text="$1"

    if command -v wl-copy >/dev/null 2>&1; then
        echo "$text" | wl-copy
    elif command -v xclip >/dev/null 2>&1; then
        echo "$text" | xclip -selection clipboard
    elif command -v xsel >/dev/null 2>&1; then
        echo "$text" | xsel --clipboard --input
    elif command -v pbcopy >/dev/null 2>&1; then
        echo "$text" | pbcopy
    elif command -v tmux >/dev/null 2>&1; then
        echo "$text" | tmux load-buffer -
    else
        echo "No clipboard utility found. Install wl-copy, xclip, xsel, pbcopy, or use tmux."
    fi
}

# -----------------------------
# Functions to Capture Command and Output
# -----------------------------

# Capture the last executed command
preexec_capture_command() {
    last_command="$1"
}

# Capture the output of the last executed command
precmd_capture_output() {
    if [[ -f "$tmp_output_file" ]]; then
        last_output=$(cat "$tmp_output_file")
        # Clear the temporary file for the next command
        > "$tmp_output_file"
    fi

    # Restore original stdout and stderr
    exec >&3 2>&4
}

# Redirect output to temporary file before each command
preexec() {
    preexec_capture_command "$1"
    # Redirect stdout and stderr to the temporary file
    exec > >(tee "$tmp_output_file") 2>&1
}

# Restore stdout and capture output after each command
precmd() {
    precmd_capture_output
}

# -----------------------------
# Define Aliases for Copying
# -----------------------------
alias lc='copy_to_clipboard "$last_command"'
alias lo='copy_to_clipboard "$last_output"'

# -----------------------------
# Save Original File Descriptors
# -----------------------------
exec 3>&1 4>&2

# -----------------------------
# Ensure the Temporary File Exists
# -----------------------------
touch "$tmp_output_file"

# -----------------------------
# Cleanup on Exit
# -----------------------------
trap 'rm -f "$tmp_output_file" 3>&- 4>&-' EXIT