#!/usr/bin/sh
# -----------------------------
# HEADER
# -----------------------------
if [ -n "$MB_CPPASTE" ]; then
    echo "cppaste already sourced. Run 'unset MB_CPPASTE' to reload."
    return
fi
export MB_CPPASTE="sourced"
# -----------------------------
# Capture Last Command and Output
# -----------------------------

# Temporary file to store command output securely
TMP_OUTPUT_FILE=$(mktemp /tmp/zsh_last_command_output_XXXXXX.txt)
chmod 600 "$TMP_OUTPUT_FILE"  # Restrict permissions

# Function to capture the last command before execution
preexec_capture_command() {
    last_command="$1"
}

# Function to capture the output of the last command after execution
precmd_capture_output() {
    if [[ -f "$TMP_OUTPUT_FILE" && -s "$TMP_OUTPUT_FILE" ]]; then
        last_output=$(< "$TMP_OUTPUT_FILE")
        # Clear the temporary file for the next command
        > "$TMP_OUTPUT_FILE"
    else
        last_output=""
    fi
}

# Set up preexec and precmd hooks
preexec() { 
    preexec_capture_command "$1" 
}
precmd() { 
    precmd_capture_output 
}

# Redirect both stdout and stderr to the temporary file
# Save original stdout and stderr
exec 3>&1 4>&2
exec > >(tee "$TMP_OUTPUT_FILE") 2>&1

# -----------------------------
# Save Last Command and Output to Files
# -----------------------------

# Function to save text to a specified file
save_to_file() {
    local text="$1"
    local file_path="$2"

    echo "$text" > "$file_path"
    echo "Saved to $file_path"
}

# -----------------------------
# Aliases to Save Last Command and Output
# -----------------------------

# Save the last executed command to ~/last_command.txt
alias lc='save_to_file "$(fc -ln -1)" ~/last_command.txt'

# Save the output of the last executed command to ~/last_output.txt
alias lo='save_to_file "$last_output" ~/last_output.txt'

# -----------------------------
# Cleanup Temporary File on Shell Exit
# -----------------------------

# Use Zsh's zshaddhistory hook to perform cleanup without traps
autoload -Uz add-zsh-hook

cleanup_temp_file() {
    if [[ -f "$TMP_OUTPUT_FILE" ]]; then
        rm -f "$TMP_OUTPUT_FILE"
    fi
}

# Add the cleanup function to the zshexit hook
add-zsh-hook zshexit cleanup_temp_file