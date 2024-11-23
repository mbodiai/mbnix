

record_terminal() {
    # Ensure the directories for pipx and bin are set up
    mkdir -p $MB_DIR/.local/pipx/venvs
    mkdir -p $MB_DIR/.local/bin
    export PIPX_HOME="$MB_DIR/.local/pipx"
    export PIPX_BIN_DIR="$MB_DIR/.local/bin"
    export PATH="$PIPX_BIN_DIR:$PATH"

    # Set a default output path if none provided
    local output_file="${1:-$MB_DIR/terminal_out.svg}"

    # Check if 'termtosvg' exists using 'type'
    if type termtosvg > /dev/null 2>&1; then
        termtosvg "$output_file"
    else
        # Clone the repository only if needed
        [ ! -d "$MB_DIR/.termtosvg" ] && git clone https://github.com/nbedos/termtosvg.git "$MB_DIR/.termtosvg"
        
        cd "$MB_DIR/.termtosvg" || return

        # Check if 'pipx' is installed; install if missing
        if ! type pipx > /dev/null 2>&1; then
            python3 -m pip install --user pipx
        pipx ensurepath
        fi

        # Use pipx to install termtosvg
        pipx install .
        
        cd - || return
        termtosvg "$output_file"
        echo "Recording saved to $output_file"
    fi
}