# Function to get Git repository info
get_git_info() {
    if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        repo_name=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
        branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        dirty_status=$(git diff --quiet || echo "*")
        printf "(g:%s@%s%s)" "$repo_name" "$branch_name" "$dirty_status"
    fi
}

# Function to get ROS workspace and package info
get_ros_info() {
    ros_ws_path=${ROS_WS_PATH:-"$HOME/ros_ws"}
    current_path=$PWD
    if [ "${current_path#"$ros_ws_path/src"}" != "$current_path" ]; then
        package_name=$(basename "$current_path")
        printf "(r:%s/%s)" "$(basename "$ros_ws_path")" "$package_name"
    elif [ "${current_path#"$ros_ws_path"}" != "$current_path" ]; then
        printf "(r:%s)" "$(basename "$ros_ws_path")"
    fi
}

# Function to get Python environment info
get_python_env() {
    if [ -n "$CONDA_DEFAULT_ENV" ]; then
        printf "(py:%s)" "$CONDA_DEFAULT_ENV"
    elif [ -n "$VIRTUAL_ENV" ]; then
        printf "(py:%s)" "$(basename "$VIRTUAL_ENV")"
    fi
}

# Construct the prompt
update_prompt() {
    git_info=$(get_git_info)
    ros_info=$(get_ros_info)
    py_env=$(get_python_env)

    PS1=""
    [ -n "$git_info" ] && PS1="${PS1}\033[1;36m$git_info\033[0m "
    [ -n "$ros_info" ] && PS1="${PS1}\033[1;32m$ros_info\033[0m "
    [ -n "$py_env" ] && PS1="${PS1}\033[1;33m$py_env\033[0m "
    PS1="${PS1}\033[1;35m\u@\h\033[0m \$ "

    # For Zsh compatibility, export PS1
    export PS1
}

# Update the prompt dynamically
PROMPT_COMMAND=update_prompt
precmd() { eval "$PROMPT_COMMAND"; }  # For Zsh