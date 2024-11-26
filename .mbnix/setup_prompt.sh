#!/bin/sh
# ============================================
# Shell Prompt Configuration Script
# Compatible with Bash and Zsh
# ============================================

# ===============================
# Set default workspace if not set
# ===============================
: "${MB_WS:="$HOME/mbnix"}"
export MB_WS


# ============================================
# Color Configuration
# ============================================
# Function to define color variables based on the shell
define_colors() {
    if [ -n "$ZSH_VERSION" ]; then
        # Zsh-specific color definitions using %{ %}
        Color_Off="%{\033[0m%}"       # Text Reset

        # Bold Colors
        BGreen="%{\033[1;32m%}"       # Green
        BPink="%{\033[1;38;5;205m%}"  # Bold Pink
        BYellow="%{\033[1;33m%}"      # Yellow
        BBlue="%{\033[1;34m%}"        # Blue
        BCyan="%{\033[1;36m%}"        # Cyan
        BGold="%{\033[1;38;5;223m%}"  # Gold
        BLightCyan="%{\033[1;38;5;87m%}"  # Light Cyan
        BMagenta="%{\033[1;35m%}"  # Magenta

    elif [ -n "$BASH_VERSION" ]; then
        # Bash-specific color definitions using \[ \]
        Color_Off='\[\033[0m\]'       # Text Reset

        # Bold Colors
        BGreen='\[\033[1;32m\]'       # Green
        BPink='\[\033[1;38;5;205m\]'  # Bold Pink
        BYellow='\[\033[1;33m\]'      # Yellow
        BBlue='\[\033[1;34m\]'        # Blue
        BCyan='\[\033[1;36m\]'        # Cyan
        BGold='\[\033[1;38;5;223m\]'  # Gold
        BLightCyan='\[\033[1;38;5;87m\]'  # Light Cyan
        BMagenta='\[\033[1;35m\]'  # Magenta
    else
        # Fallback if neither Bash nor Zsh
        Color_Off=''
        BGreen=''
        BPink=''
        BYellow=''
        BBlue=''
    fi
}

# Initialize color definitions
define_colors

# Function to apply color to text
colorize_text() {
    text="$1"
    color="$2"
    if [ -n "$ZSH_VERSION" ]; then
        # Use echo in Zsh to avoid printf misinterpretation
        echo "${color}${text}${Color_Off}"
    elif [ -n "$BASH_VERSION" ]; then
        # Use printf in Bash as before
        printf "${color}%s${Color_Off}" "$text"
    else
        # Fallback to plain text if neither shell
        printf "%s" "$text"
    fi
}

# ===============================
# Configuration Variables
# ===============================

# Enable or disable prompt modules
ENABLE_GIT_INFO=true
ENABLE_ROS_INFO=true
ENABLE_PYTHON_ENV=true
ENABLE_COLORS=true
ENABLE_HOST_INFO=true

# Colors for each module
GIT_COLOR="$BGreen"
ROS_COLOR="$BPink"
HOST_COLOR="$BCyan"
PYTHON_COLOR=""
CWD_COLOR="$BBlue"

# Define if minimal mode is active
MINIMAL=${MINIMAL:-true}
DELIM=" "
# ============================================
# Prompt Syntax Configuration
# ============================================
get_host_info() {  
  local suffix="$DELIM"
  if [ "$ENABLE_HOST_INFO" = true ]; then
    if [ "$MINIMAL" = false ]; then
        suffix="@$DELIM"
    fi
    if [ -n "$ZSH_VERSION" ]; then  
        # Zsh: %n is interpreted directly in the prompt  
        # We'll include it directly in the prompt string  
        # Instead of using printf, handle it in the prompt construction  
        echo '%n'"$suffix"
    elif [ -n "$BASH_VERSION" ]; then  
        printf "%s%s " "$(whoami)" "$suffix"
    fi
  fi
}  

# Module: Git Information
get_git_info() {
    if [ "$ENABLE_GIT_INFO" = true ] && command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch_name dirty_status
        branch_name=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if git diff --quiet >/dev/null 2>&1; then
            dirty_status=""
        else
            dirty_status="*"
        fi

        if [ "$MINIMAL" = true ]; then
            printf "[%s%s]$DELIM" "$branch_name" "$dirty_status"
        else
            printf "(g:%s@%s)" "$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")" "$branch_name$dirty_status"
        fi
    fi
}


# Module: ROS Workspace Information
get_ros_info() {
    if [ "$ENABLE_ROS_INFO" = true ]; then
        local ros_ws_path=${ROS_WS_PATH:-"$HOME/ros_ws"}
        local current_path="$PWD"

        if [ "${current_path#"$ros_ws_path/src"}" != "$current_path" ]; then
            local package_name
            package_name=$(basename "$current_path")
            printf "(r:%s/%s)" "$(basename "$ros_ws_path")" "$package_name"
        elif [ "${current_path#"$ros_ws_path"}" != "$current_path" ]; then
            printf "(r:%s)" "$(basename "$ros_ws_path")"
        fi
    fi
}


get_python_env() {
    if [ "$ENABLE_PYTHON_ENV" = true ]; then
        envs=""

        if [ -n "$CONDA_DEFAULT_ENV" ]; then
            envs="$CONDA_DEFAULT_ENV"
        fi

        if [ -n "$VIRTUAL_ENV" ]; then
            if [ -n "$envs" ]; then
                envs="$envs:$(basename "$VIRTUAL_ENV")"
            else
                envs="$(basename "$VIRTUAL_ENV")"
            fi
        fi

        if [ -n "$envs" ]; then
            if [ "$MINIMAL" = true ]; then
                printf "(%s)$DELIM" "$envs"
            else
                printf "(py:%s)$DELIM" "$envs"
            fi
        fi
    fi
}


get_cwd() {
    local cwd="$PWD"
    # Remove trailing slash from $HOME for consistency
    local home="${HOME%/}"

    if [ "$cwd" = "$home" ]; then
        cwd="~"
    elif [[ "$cwd" = "$home/"* ]]; then
        cwd="~${cwd#$home}"
    fi
    printf "%s" "$cwd"
}

# ============================================
# Toggle Functions
# ============================================

# Toggle Git Information
toggle_git() {
    if [ "$ENABLE_GIT_INFO" = true ]; then
        ENABLE_GIT_INFO=false
        echo "Git information disabled in prompt."
    else
        ENABLE_GIT_INFO=true
        echo "Git information enabled in prompt."
    fi
    update_prompt
}

# Toggle ROS Information
toggle_ros() {
    if [ "$ENABLE_ROS_INFO" = true ]; then
        ENABLE_ROS_INFO=false
        echo "ROS information disabled in prompt."
    else
        ENABLE_ROS_INFO=true
        echo "ROS information enabled in prompt."
    fi
    update_prompt
}

# Toggle Python Environment
toggle_python() {
    if [ "$ENABLE_PYTHON_ENV" = true ]; then
        ENABLE_PYTHON_ENV=false
        echo "Python environment display disabled in prompt."
    else
        ENABLE_PYTHON_ENV=true
        echo "Python environment display enabled in prompt."
    fi
    update_prompt
}

# Toggle Colors
toggle_colors() {
    if [ "$ENABLE_COLORS" = true ]; then
        ENABLE_COLORS=false
        echo "Colors disabled in prompt."
    else
        ENABLE_COLORS=true
        echo "Colors enabled in prompt."
    fi
    define_colors
    update_prompt
}

toggle_host() {
    if [ "$ENABLE_HOST_INFO" = true ]; then
        ENABLE_HOST_INFO=false
        echo "Host information disabled in prompt."
    else
        ENABLE_HOST_INFO=true
        echo "Host information enabled in prompt."
    fi
    update_prompt
}

toggle_minimal() {
    if [ "$MINIMAL" = true ]; then
        MINIMAL=false
        echo "Minimal mode disabled."
    else
        MINIMAL=true
        echo "Minimal mode enabled."
    fi
    update_prompt
}
# ============================================
# Aliases for Toggling
# ============================================

alias togglegit='toggle_git'
alias toggleros='toggle_ros'
alias togglepy='toggle_python'
alias togglecolor='toggle_colors'
alias toggleprompt='update_prompt'
alias togglehost='toggle_host'
alias toggleminimal='toggle_minimal'

# ============================================
# Construct the Prompt
# ============================================

construct_prompt() {
    local git_info ros_info py_env cwd
    local prompt_parts=()

    # Gather info from modules
    host_info=$(get_host_info)
    git_info=$(get_git_info)
    ros_info=$(get_ros_info)
    py_env=$(get_python_env)
    cwd=$(get_cwd)

    # Assemble prompt with colors if enabled
    if [ "$ENABLE_COLORS" = true ]; then
        [ -n "$host_info" ] && prompt_parts+=("$(colorize_text "$host_info" "$HOST_COLOR")")
        [ -n "$git_info" ] && prompt_parts+=("$(colorize_text "$git_info" "$GIT_COLOR")")
        [ -n "$ros_info" ] && prompt_parts+=("$(colorize_text "$ros_info" "$ROS_COLOR")")
        [ -n "$py_env" ] && prompt_parts+=("$(colorize_text "$py_env" "$PYTHON_COLOR")")
        [ -n "$cwd" ] && prompt_parts+=("$(colorize_text "$cwd" "$CWD_COLOR")")
    else
        # Without colors, simply add the modules
        [ -n "$host_info" ] && prompt_parts+=("$host_info")
        [ -n "$git_info" ] && prompt_parts+=("$git_info")
        [ -n "$ros_info" ] && prompt_parts+=("$ros_info")
        [ -n "$py_env" ] && prompt_parts+=("$py_env")
        [ -n "$cwd" ] && prompt_parts+=("$cwd")
    fi

    # Determine the prompt symbol based on shell
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_PROMPT="%# "
    else
        SHELL_PROMPT="$ "
    fi

    # Combine all parts into PS1 with appropriate separators
    local joined
    joined=$(IFS="$SEPARATOR"; echo "${prompt_parts[*]}")
    PS1="${joined} ${SHELL_PROMPT}"
}
construct_rprompt() {
  echo " "
  # RPROMPT=' %~'     # prompt for right side of screen
}
# ============================================
# Update the Shell Prompt
# ============================================

update_prompt() {
    construct_prompt
}

# ============================================
# Hook into Shell's Prompt Update Mechanism
# ============================================

if [ -n "$ZSH_VERSION" ]; then
    # For Zsh, use precmd hook
    precmd() {
        update_prompt
    }
elif [ -n "$BASH_VERSION" ]; then
    # For Bash, use PROMPT_COMMAND
    PROMPT_COMMAND=update_prompt
fi

# Initialize the prompt on script load
update_prompt

