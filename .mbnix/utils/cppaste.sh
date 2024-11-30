#!/usr/bin/zsh

# Guard against multiple sourcing
if [ -n "$_CPPASTE_MBNIX_RUNNING" ]; then
    return 0
fi
export _CPPASTE_MBNIX_RUNNING=1

# Initialize variables
typeset -g last_command=""
typeset -g last_output=""
typeset -g TMP_OUTPUT_FILE
TMP_OUTPUT_FILE=$(mktemp /tmp/zsh_last_command_output_XXXXXX.txt)
chmod 600 "$TMP_OUTPUT_FILE"

# Hook before command execution
function _pre_exec() {
    last_command="$1"
    # Clear the temporary file
    : > "$TMP_OUTPUT_FILE"
}

# Hook after command execution
function _pre_cmd() {
    # Append the command output to the temporary file
    # This assumes `last_output` is only needed interactively
    if [ -s "$TMP_OUTPUT_FILE" ]; then
        last_output=$(<"$TMP_OUTPUT_FILE")
    fi
}

# Save functions
function save_to_file() {
    local text="$1"
    local file_path="$2"
    echo "$text" > "$file_path"
    echo "Saved to $file_path"
}

# Cleanup function
function _cleanup() {
    [ -f "$TMP_OUTPUT_FILE" ] && rm -f "$TMP_OUTPUT_FILE"
}

# Set up aliases
alias lc='save_to_file "$(fc -ln -1)" ~/last_command.txt'
alias lo='save_to_file "$last_output" ~/last_output.txt'

# Add hooks
autoload -Uz add-zsh-hook
add-zsh-hook preexec _pre_exec
add-zsh-hook precmd _pre_cmd
add-zsh-hook zshexit _cleanup

# Unset running guard
unset _CPPASTE_MBNIX_RUNNING