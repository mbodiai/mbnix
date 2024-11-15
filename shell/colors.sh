#!/bin/sh
# Define color variables without shell-specific syntax
GOLD="\033[38;5;223m"
GOLD_BOLD="\033[01;38;5;223m"
RESET='\033[0m'
RED='\033[31m'
RED_BOLD='\033[01;31m'
GREEN='\033[32m'
GREEN_BOLD='\033[01;32m'
PINK="\033[38;5;225m"
PINK_BOLD="\033[01;38;5;225m"
YELLOW='\033[33m'
YELLOW_BOLD='\033[01;33m'
BLUE='\033[34m'
BLUE_BOLD='\033[01;34m'
MAGENTA='\033[35m'
CYAN='\033[36m'
LIGHT_CYAN="\033[38;5;87m"
LIGHT_CYAN_BOLD="\033[01;38;5;87m"
CYAN_BOLD='\033[01;36m'

# Disable immediate job notifications
unsetopt notify

# Function to display error messages and exit
oops() {
    printf "${RED_BOLD}Error:${RESET} %s\n" "$1" >&2
}

# Validate MB_WS environment variable
if [ -z "$MB_WS" ]; then
    oops "Set MB_WS to the workspace directory."
fi

# Validate MB_COLOR environment variable
validate_mb_color() {
    if [ -z "$MB_COLOR" ]; then
        printf ""
        # printf "Tip: You can set MB_COLOR to one of the following colors: RED, GREEN, PINK, CYAN, YELLOW, BLUE, MAGENTA, PINK_BOLD, CYAN_BOLD\n"
        MB_COLOR="$PINK_BOLD" # Default color (Pink Bold)
    else

        # Define a list of valid ANSI color names
        valid_colors="RED|GREEN|PINK|CYAN|YELLOW|BLUE|MAGENTA|PINK_BOLD|CYAN_BOLD"

        # Check if MB_COLOR matches one of the valid colors
        case "$MB_COLOR" in
        RED | GREEN | PINK | CYAN | YELLOW | BLUE | MAGENTA | PINK_BOLD | CYAN_BOLD)
            # Assign the corresponding ANSI code
            MB_COLOR=$(eval echo "\$$MB_COLOR")
            ;;
        *)
            # Invalid color
            echo "${RED_BOLD}Error:${RESET} Invalid MB_COLOR value: $MB_COLOR. Must be one of ${RED}RED${RESET}, ${GREEN}GREEN${RESET}, ${PINK}PINK${RESET}, ${CYAN}CYAN${RESET}, ${YELLOW}YELLOW${RESET}, ${BLUE}BLUE${RESET}, ${MAGENTA}MAGENTA${RESET}"
            ;;
        esac
    fi
}

# Color codes
warm_colors="196 202 208 214 220 226 190 154 118 82"
cool_colors="51 45 39 33 27 21 18 15 12 9"
pinkish_colors="225"

# Function to display animated message with dots
animate_message() {
    message="${1:-Building your workspace}"
    sleeptime="${2:-3}"
    colors="${3:-$pinkish_colors}"
    num_colors=$(echo "$colors" | wc -w)
    delay=0.04
    max_iter=50
    message_switch_delay=1.5
    colored_message=""

    # Animate each character appearing one after the other
    i=1
    message_length=${#message}
    while [ "$i" -le "$message_length" ]; do
        char=$(printf '%s' "$message" | cut -c "$i")
        color_code=$(echo "$colors" | awk -v pos="$i" -v num_colors="$num_colors" '{split($0,a," "); print a[((pos-1)%num_colors)+1]}')
        colored_message="${colored_message}\033[38;5;${color_code}m${char}"
        printf "%b" "\r\033[K${colored_message}${RESET}"
        i=$((i + 1))
        sleep "$delay"
    done

    # Dynamic ellipsis animation with cooler colors
    dots=""
    max_dots=4
    delay=0.1
    for iter in $(seq 1 "$max_iter"); do
        for j in $(seq 1 "$max_dots"); do
            dots="$(printf '.%.0s' $(seq 1 "$j"))"
            color_index=$(((iter + j - 1) % $(echo "$cool_colors" | wc -w) + 1))
            color_code=$(echo "$cool_colors" | awk -v idx="$color_index" '{split($0,a," "); print a[idx]}')
            printf "%b" "\r\033[K${colored_message}\033[38;5;${color_code}m${dots}${RESET}"
            sleep "$delay"
        done
    done

    # Print the final message in a cool color
    final_color=$(echo "$cool_colors" | awk '{split($0,a," "); print a[length(a)]}')
    printf "%b\n" "\r\033[K\033[38;5;${final_color}m${message}${RESET}"

    # Sleep for a bit before switching to the next message
    sleep "$message_switch_delay"
}

# Main Execution Flow
validate_mb_color

# Start the first animation in the background
animate_message "Building your workspace" 2 "$warm_colors $cool_colors" &
pid1=$! # Capture the PID of the first animation
sleep 2
kill "$pid1" # Terminate the first animation

# Start the second animation in the background
animate_message "from mbodi ai" 2 "$PINK_BOLD" &
pid2=$! # Capture the PID of the second animation
sleep 2
kill "$pid2" # Terminate the second animation

# Export color variables
export MB_COLOR
export RESET="$RESET"
export RED="$RED"
export RED_BOLD="$RED_BOLD"
export GREEN="$GREEN"
export GREEN_BOLD="$GREEN_BOLD"
export PINK="$PINK"
export PINK_BOLD="$PINK_BOLD"
export YELLOW="$YELLOW"
export BLUE="$BLUE"
export BLUE_BOLD="$BLUE_BOLD"
export MAGENTA="$MAGENTA"
export CYAN="$CYAN"
export LIGHT_CYAN="$LIGHT_CYAN"
export LIGHT_CYAN_BOLD="$LIGHT_CYAN_BOLD"
export CYAN_BOLD="$CYAN_BOLD"
export GOLD="$GOLD"
export GOLD_BOLD="$GOLD_BOLD"
