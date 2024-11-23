#!/bin/sh
# File: ctest.sh

# Define color variables using ANSI escape codes
GOLD=$'\033[38;5;223m'
GOLD_BOLD=$'\033[01;38;5;223m'
RESET=$'\033[0m'
RED=$'\033[31m'
RED_BOLD=$'\033[01;31m'
GREEN=$'\033[32m'
GREEN_BOLD=$'\033[01;32m'
PINK=$'\033[38;5;225m'
PINK_BOLD=$'\033[01;38;5;225m'
YELLOW=$'\033[33m'
YELLOW_BOLD=$'\033[01;33m'
BLUE=$'\033[34m'
BLUE_BOLD=$'\033[01;34m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
LIGHT_CYAN=$'\033[38;5;87m'
LIGHT_CYAN_BOLD=$'\033[01;38;5;87m'
CYAN_BOLD=$'\033[01;36m'



# Function to display error messages
oops() {
    printf "%b\n" "${RED_BOLD}Error:${RESET} $1" >&2
}
warn() {
    printf "%b\n" "${YELLOW}Warning:${RESET} $1" >&2
}

# Validate MB_WS environment variable
if [ -z "$MB_WS" ]; then
    warn "MB_WS is not set. Setting to $HOME/MBNIX."
fi

# Validate MB_COLOR environment variable
validate_mb_color() {
    if [ -z "$MB_COLOR" ]; then
        MB_COLOR="PINK_BOLD"  # Default color name
    fi

    case "$MB_COLOR" in
        RED|GREEN|PINK|CYAN|YELLOW|BLUE|MAGENTA|PINK_BOLD|CYAN_BOLD)
            eval "MB_COLOR=\"\$$MB_COLOR\""
            ;;
        *$'\033'*)
            # MB_COLOR is already an escape sequence; accept it
            ;;
        *)
            oops "Invalid MB_COLOR value: $MB_COLOR. Must be a valid color name or escape code."
            MB_COLOR="$PINK_BOLD"  # Fallback to default escape code
            ;;
    esac
}


# Adjusted animate_message function with animation flag
animate_message() {
    message="${1:-}"
    sleeptime="${2:-}"
    color="${3:-}"
    startat="${4:-1}"
    animate_msg="${5:-1}"  # 1 to animate message, 0 to display instantly

    # Accelerated delays
    delay=0.05       # Speed up character display
    dots_delay=0.1   # Speed up dots animation
    max_dots=3

    # Display the message
    printf "%b" "$color"
    if [ "$animate_msg" -eq 1 ]; then
        # Animate message one letter at a time
        i="$startat"
        message_length=$(printf '%s' "$message" | wc -c)
        while [ "$i" -le "$message_length" ]; do
            char=$(printf '%s' "$message" | cut -c "$i")
            printf "%b" "$char"
            sleep "$delay"
            i=$((i + 1))
        done
    else
        # Display message instantly
        printf "%b" "$message"
    fi

    # Animate dots after the message
    end_time=$(( $(date +%s) + sleeptime ))
    dot_count=0
    while [ "$(date +%s)" -lt "$end_time" ]; do
        dots=""
        num_dots=$(( (dot_count % max_dots) + 1 ))
        j=1
        while [ "$j" -le "$num_dots" ]; do
            dots="$dots."
            j=$((j + 1))
        done
        printf "\r%b%b%b%b" "$color" "$message" "$dots" "$RESET"
        sleep "$dots_delay"
        dot_count=$((dot_count + 1))
    done
    printf "%b\n" "$RESET"
}

# Animate both message and dots
animate_message "building your workspace" 1 "$GOLD_BOLD" 1 1

# Display message instantly, animate only dots
MB_COLOR="$COLOR2"
animate_message "from mbodi ai" 1 "$PINK_BOLD" 1 0

# Export color variables for use in other scripts or prompts
export MB_COLOR RESET RED RED_BOLD GREEN GREEN_BOLD \
       PINK PINK_BOLD YELLOW YELLOW_BOLD BLUE BLUE_BOLD \
       MAGENTA CYAN LIGHT_CYAN LIGHT_CYAN_BOLD CYAN_BOLD \
       GOLD GOLD_BOLD