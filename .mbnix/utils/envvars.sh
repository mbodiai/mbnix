#!/bin/sh
if [ -n "$MB_ENVVARS" ]; then
    echo "MB_ENVVARS already sourced. Run 'unset MB_ENVVARS' to reload."
    return
fi
export MB_ENVVARS="sourced"
setup_envs() {
    # List of common directories to search for binaries
    COMMON_BIN_DIRS="/usr/local/bin /usr/bin /bin /usr/local/cuda/bin"

    # Function to search for a binary in common directories
    find_binary() {
        binary_name="$1"
        for dir in $COMMON_BIN_DIRS; do
            if [ -x "$dir/$binary_name" ]; then
                echo "$dir/$binary_name"
                return 0
            fi
        done
        return 1
    }

    # Function to search for a directory in common locations
    find_directory() {
        dir_name="$1"
        for base_dir in "/usr/local" "/opt" "/usr"; do
            if [ -d "$base_dir/$dir_name" ]; then
                echo "$base_dir/$dir_name"
                return 0
            fi
        done
        return 1
    }

    # Prompt the user for optimal environment variable settings
    printf "Do you want to set environment variables to optimal values for your system? [yes/no]: "
    read -r response

    # Initialize a list to track variables set by this script
    MB_SETUP_VARS=""
    MB_ADDED_PATHS=""

    if [ "$response" = "yes" ]; then
        echo "Setting environment variables to optimal values..."

        # ================================
        # C++/Build Environment Variables
        # ================================

        # Set CXX
        CXX_PATH=$(find_binary "g++")
        if [ -n "$CXX_PATH" ]; then
            export CXX="$CXX_PATH"
            MB_SETUP_VARS="$MB_SETUP_VARS CXX"
            echo "Set CXX to $CXX"
        else
            echo "g++ not found. CXX not set."
        fi

        # Set CC
        CC_PATH=$(find_binary "gcc")
        if [ -n "$CC_PATH" ]; then
            export CC="$CC_PATH"
            MB_SETUP_VARS="$MB_SETUP_VARS CC"
            echo "Set CC to $CC_PATH"
        else
            echo "gcc not found. CC not set."
        fi

        # Set CMAKE_PREFIX_PATH
        export CMAKE_PREFIX_PATH="/"
        MB_SETUP_VARS="$MB_SETUP_VARS CMAKE_PREFIX_PATH"
        echo "Set CMAKE_PREFIX_PATH to /"

        # Set LD_LIBRARY_PATH
        if [ -d "/usr/local/lib" ]; then
            if echo "$LD_LIBRARY_PATH" | grep -q "/usr/local/lib"; then
                echo "/usr/local/lib is already in LD_LIBRARY_PATH. Not adding."
            else
                export LD_LIBRARY_PATH="/usr/local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
                MB_SETUP_VARS="$MB_SETUP_VARS LD_LIBRARY_PATH"
                MB_ADDED_PATHS="$MB_ADDED_PATHS /usr/local/lib"
                echo "Added /usr/local/lib to LD_LIBRARY_PATH"
            fi
        else
            echo "/usr/local/lib does not exist. LD_LIBRARY_PATH not modified."
        fi

        # Set INCLUDE_PATH
        if [ -d "/usr/include" ]; then
            export INCLUDE_PATH="/usr/include"
            MB_SETUP_VARS="$MB_SETUP_VARS INCLUDE_PATH"
            echo "Set INCLUDE_PATH to /usr/include"
        else
            echo "/usr/include does not exist. INCLUDE_PATH not set."
        fi

        # ================================
        # CUDA/GPU Environment Variables
        # ================================

        # Find nvcc
        NVCC_PATH=$(find_binary "nvcc")
        if [ -n "$NVCC_PATH" ]; then
            CUDA_HOME=$(dirname "$(dirname "$NVCC_PATH")")
            export CUDA_HOME="$CUDA_HOME"
            export CUDA_PATH="$CUDA_HOME"
            MB_SETUP_VARS="$MB_SETUP_VARS CUDA_HOME CUDA_PATH"
            echo "Set CUDA_HOME to $CUDA_HOME"
            echo "Set CUDA_PATH to $CUDA_HOME"
        else
            # Attempt to find CUDA directory
            CUDA_HOME_DIR=$(find_directory "cuda")
            if [ -n "$CUDA_HOME_DIR" ]; then
                CUDA_HOME="$CUDA_HOME_DIR"
                export CUDA_HOME="$CUDA_HOME"
                export CUDA_PATH="$CUDA_HOME"
                MB_SETUP_VARS="$MB_SETUP_VARS CUDA_HOME CUDA_PATH"
                echo "Set CUDA_HOME to $CUDA_HOME"
                echo "Set CUDA_PATH to $CUDA_HOME"
            else
                echo "CUDA not found. CUDA_HOME and CUDA_PATH not set."
            fi
        fi

        # Set NVIDIA_DRIVER_CAPABILITIES
        export NVIDIA_DRIVER_CAPABILITIES="all"
        MB_SETUP_VARS="$MB_SETUP_VARS NVIDIA_DRIVER_CAPABILITIES"
        echo "Set NVIDIA_DRIVER_CAPABILITIES to all"

        # Update PATH
        if [ -n "$CUDA_HOME" ] && [ -d "$CUDA_HOME/bin" ]; then
            if echo "$PATH" | grep -q "$CUDA_HOME/bin"; then
                echo "$CUDA_HOME/bin is already in PATH. Not adding."
            else
                export PATH="$CUDA_HOME/bin${PATH:+:$PATH}"
                MB_SETUP_VARS="$MB_SETUP_VARS PATH"
                MB_ADDED_PATHS="$MB_ADDED_PATHS $CUDA_HOME/bin"
                echo "Added $CUDA_HOME/bin to PATH"
            fi
        else
            echo "$CUDA_HOME/bin does not exist. PATH not modified."
        fi

        # Update LD_LIBRARY_PATH for CUDA
        if [ -n "$CUDA_HOME" ] && [ -d "$CUDA_HOME/lib64" ]; then
            if echo "$LD_LIBRARY_PATH" | grep -q "$CUDA_HOME/lib64"; then
                echo "$CUDA_HOME/lib64 is already in LD_LIBRARY_PATH. Not adding."
            else
                export LD_LIBRARY_PATH="$CUDA_HOME/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
                MB_SETUP_VARS="$MB_SETUP_VARS LD_LIBRARY_PATH"
                MB_ADDED_PATHS="$MB_ADDED_PATHS $CUDA_HOME/lib64"
                echo "Added $CUDA_HOME/lib64 to LD_LIBRARY_PATH"
            fi
        else
            echo "$CUDA_HOME/lib64 does not exist. LD_LIBRARY_PATH not modified."
        fi

    else
        echo "Manual configuration selected."

        # ================================
        # C++/Build Environment Variables
        # ================================

        # Set CXX
        printf "Set CXX (current: %s, default: /usr/bin/g++): " "${CXX:-not set}"
        read -r input
        if [ -n "$input" ]; then
            if [ -x "$input" ]; then
                export CXX="$input"
                MB_SETUP_VARS="$MB_SETUP_VARS CXX"
                echo "Set CXX to $input"
            else
                echo "Specified CXX ($input) is not executable. CXX not set."
            fi
        else
            default_cxx="/usr/bin/g++"
            if [ -x "$default_cxx" ]; then
                export CXX="$default_cxx"
                MB_SETUP_VARS="$MB_SETUP_VARS CXX"
                echo "Set CXX to $default_cxx"
            else
                echo "Default CXX ($default_cxx) not found. CXX not set."
            fi
        fi

        # Set CC
        printf "Set CC (current: %s, default: /usr/bin/gcc): " "${CC:-not set}"
        read -r input
        if [ -n "$input" ]; then
            if [ -x "$input" ]; then
                export CC="$input"
                MB_SETUP_VARS="$MB_SETUP_VARS CC"
                echo "Set CC to $input"
            else
                echo "Specified CC ($input) is not executable. CC not set."
            fi
        else
            default_cc="/usr/bin/gcc"
            if [ -x "$default_cc" ]; then
                export CC="$default_cc"
                MB_SETUP_VARS="$MB_SETUP_VARS CC"
                echo "Set CC to $default_cc"
            else
                echo "Default CC ($default_cc) not found. CC not set."
            fi
        fi

        # Set CMAKE_PREFIX_PATH
        printf "Set CMAKE_PREFIX_PATH (current: %s, default: /): " "${CMAKE_PREFIX_PATH:-not set}"
        read -r input
        export CMAKE_PREFIX_PATH="${input:-/}"
        MB_SETUP_VARS="$MB_SETUP_VARS CMAKE_PREFIX_PATH"
        echo "Set CMAKE_PREFIX_PATH to ${input:-/}"

        # Set LD_LIBRARY_PATH
        printf "Set LD_LIBRARY_PATH (current: %s, default: /usr/local/lib): " "${LD_LIBRARY_PATH:-not set}"
        read -r input
        if [ -n "$input" ]; then
            if [ -d "$input" ]; then
                if echo "$LD_LIBRARY_PATH" | grep -q "$input"; then
                    echo "$input is already in LD_LIBRARY_PATH. Not adding."
                else
                    export LD_LIBRARY_PATH="$input${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
                    MB_SETUP_VARS="$MB_SETUP_VARS LD_LIBRARY_PATH"
                    MB_ADDED_PATHS="$MB_ADDED_PATHS $input"
                    echo "Added $input to LD_LIBRARY_PATH"
                fi
            else
                echo "Specified LD_LIBRARY_PATH directory ($input) does not exist. LD_LIBRARY_PATH not modified."
            fi
        else
            default_ld="/usr/local/lib"
            if [ -d "$default_ld" ]; then
                if echo "$LD_LIBRARY_PATH" | grep -q "$default_ld"; then
                    echo "$default_ld is already in LD_LIBRARY_PATH. Not adding."
                else
                    export LD_LIBRARY_PATH="$default_ld${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
                    MB_SETUP_VARS="$MB_SETUP_VARS LD_LIBRARY_PATH"
                    MB_ADDED_PATHS="$MB_ADDED_PATHS $default_ld"
                    echo "Added $default_ld to LD_LIBRARY_PATH"
                fi
            else
                echo "Default LD_LIBRARY_PATH directory ($default_ld) does not exist. LD_LIBRARY_PATH not modified."
            fi
        fi

        # Set INCLUDE_PATH
        printf "Set INCLUDE_PATH (current: %s, default: /usr/include): " "${INCLUDE_PATH:-not set}"
        read -r input
        if [ -n "$input" ]; then
            if [ -d "$input" ]; then
                export INCLUDE_PATH="$input"
                MB_SETUP_VARS="$MB_SETUP_VARS INCLUDE_PATH"
                echo "Set INCLUDE_PATH to $input"
            else
                echo "Specified INCLUDE_PATH directory ($input) does not exist. INCLUDE_PATH not set."
            fi
        else
            default_include="/usr/include"
            if [ -d "$default_include" ]; then
                export INCLUDE_PATH="$default_include"
                MB_SETUP_VARS="$MB_SETUP_VARS INCLUDE_PATH"
                echo "Set INCLUDE_PATH to $default_include"
            else
                echo "Default INCLUDE_PATH directory ($default_include) does not exist. INCLUDE_PATH not set."
            fi
        fi

        # ================================
        # CUDA/GPU Environment Variables
        # ================================

        # Set CUDA_HOME
        printf "Set CUDA_HOME (current: %s, default: /usr/local/cuda): " "${CUDA_HOME:-not set}"
        read -r input
        if [ -n "$input" ]; then
            if [ -d "$input" ]; then
                export CUDA_HOME="$input"
                MB_SETUP_VARS="$MB_SETUP_VARS CUDA_HOME"
                echo "Set CUDA_HOME to $input"
            else
                echo "Specified CUDA_HOME directory ($input) does not exist. CUDA_HOME not set."
            fi
        else
            default_cuda="/usr/local/cuda"
            if [ -d "$default_cuda" ]; then
                export CUDA_HOME="$default_cuda"
                MB_SETUP_VARS="$MB_SETUP_VARS CUDA_HOME"
                echo "Set CUDA_HOME to $default_cuda"
            else
                echo "Default CUDA_HOME directory ($default_cuda) does not exist. CUDA_HOME not set."
            fi
        fi

        # Set CUDA_PATH
        if [ -n "$CUDA_HOME" ]; then
            export CUDA_PATH="$CUDA_HOME"
            MB_SETUP_VARS="$MB_SETUP_VARS CUDA_PATH"
            echo "Set CUDA_PATH to $CUDA_HOME"
        else
            echo "CUDA_HOME not set. CUDA_PATH not set."
        fi

        # Set NVIDIA_DRIVER_CAPABILITIES
        export NVIDIA_DRIVER_CAPABILITIES="all"
        MB_SETUP_VARS="$MB_SETUP_VARS NVIDIA_DRIVER_CAPABILITIES"
        echo "Set NVIDIA_DRIVER_CAPABILITIES to all"

        # Update PATH for CUDA binaries
        printf "Set PATH to include CUDA binaries (current PATH: %s): " "$PATH"
        read -r input
        if [ -n "$input" ]; then
            if [ -d "$input" ]; then
                if echo "$PATH" | grep -q "$input"; then
                    echo "$input is already in PATH. Not adding."
                else
                    export PATH="$input:$PATH"
                    MB_SETUP_VARS="$MB_SETUP_VARS PATH"
                    MB_ADDED_PATHS="$MB_ADDED_PATHS $input"
                    echo "Added $input to PATH"
                fi
            else
                echo "Specified CUDA bin directory ($input) does not exist. PATH not modified."
            fi
        else
            if [ -n "$CUDA_HOME" ] && [ -d "$CUDA_HOME/bin" ]; then
                if echo "$PATH" | grep -q "$CUDA_HOME/bin"; then
                    echo "$CUDA_HOME/bin is already in PATH. Not adding."
                else
                    export PATH="$CUDA_HOME/bin:$PATH"
                    MB_SETUP_VARS="$MB_SETUP_VARS PATH"
                    MB_ADDED_PATHS="$MB_ADDED_PATHS $CUDA_HOME/bin"
                    echo "Added $CUDA_HOME/bin to PATH"
                fi
            else
                echo "$CUDA_HOME/bin does not exist. PATH not modified."
            fi
        fi

        # Update LD_LIBRARY_PATH for CUDA libraries
        printf "Set LD_LIBRARY_PATH to include CUDA libraries (current LD_LIBRARY_PATH: %s): " "${LD_LIBRARY_PATH:-not set}"
        read -r input
        if [ -n "$input" ]; then
            if [ -d "$input" ]; then
                if echo "$LD_LIBRARY_PATH" | grep -q "$input"; then
                    echo "$input is already in LD_LIBRARY_PATH. Not adding."
                else
                    export LD_LIBRARY_PATH="$input${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
                    MB_SETUP_VARS="$MB_SETUP_VARS LD_LIBRARY_PATH"
                    MB_ADDED_PATHS="$MB_ADDED_PATHS $input"
                    echo "Added $input to LD_LIBRARY_PATH"
                fi
            else
                echo "Specified CUDA lib directory ($input) does not exist. LD_LIBRARY_PATH not modified."
            fi
        else
            if [ -n "$CUDA_HOME" ] && [ -d "$CUDA_HOME/lib64" ]; then
                if echo "$LD_LIBRARY_PATH" | grep -q "$CUDA_HOME/lib64"; then
                    echo "$CUDA_HOME/lib64 is already in LD_LIBRARY_PATH. Not adding."
                else
                    export LD_LIBRARY_PATH="$CUDA_HOME/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
                    MB_SETUP_VARS="$MB_SETUP_VARS LD_LIBRARY_PATH"
                    MB_ADDED_PATHS="$MB_ADDED_PATHS $CUDA_HOME/lib64"
                    echo "Added $CUDA_HOME/lib64 to LD_LIBRARY_PATH"
                fi
            else
                echo "$CUDA_HOME/lib64 does not exist. LD_LIBRARY_PATH not modified."
            fi
        fi
    fi

    # Mark the variables set by this script for later reset
    if [ -n "$MB_SETUP_VARS" ]; then
        export MB_SETUP_ENV_VARS="$MB_SETUP_VARS"
    fi

    # Track the specific paths added for precise removal
    if [ -n "$MB_ADDED_PATHS" ]; then
        export MB_ADDED_PATHS="$MB_ADDED_PATHS"
    fi

    # Display the set environment variables
    echo "Environment variables set by setup_envs:"
    for var in $MB_SETUP_VARS; do
        eval "echo \"$var=\$$var\""
    done
}

# Function to reset environment variables set by setup_envs
reset_envs() {
    if [ -z "$MB_SETUP_ENV_VARS" ]; then
        echo "No environment variables set by setup_envs to reset."
        return 0
    fi

    echo "Unsetting environment variables set by setup_envs..."

    # Iterate over the list of variables set by setup_envs and unset them
    for var in $MB_SETUP_ENV_VARS; do
        unset "$var"
        echo "Unset $var"
    done

    # Remove the specific paths added to PATH
    if [ -n "$MB_ADDED_PATHS" ]; then
        for path in $MB_ADDED_PATHS; do
            # Remove the exact path from PATH
            PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^$path$" | paste -sd: -)
        done
        export PATH
        echo "Removed added paths from PATH."
    fi

    # Remove the specific paths added to LD_LIBRARY_PATH
    if [ -n "$MB_ADDED_PATHS" ]; then
        for path in $MB_ADDED_PATHS; do
            # Remove the exact path from LD_LIBRARY_PATH
            LD_LIBRARY_PATH=$(echo "$LD_LIBRARY_PATH" | tr ':' '\n' | grep -v "^$path$" | paste -sd: -)
        done
        export LD_LIBRARY_PATH
        echo "Removed added paths from LD_LIBRARY_PATH."
    fi

    # Unset the setup environment variable trackers
    unset MB_SETUP_ENV_VARS
    unset MB_ADDED_PATHS

    echo "Environment variables have been reset."
}
export setup_envs
export reset_envs

