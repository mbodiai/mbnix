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


clear_line() {
    # Fallback if tput not available
    if command -v tput >/dev/null 2>&1; then
        tput el >/dev/null 2>&1
    fi
    # Always use ANSI escape as backup
    printf "\r\033[K"
}

animate_message() {
    # Guard against recursive calls and check shell
    if [ -n "$_ANIMATE_RUNNING" ]; then
        return 0
    fi
    export _ANIMATE_RUNNING=1

    # Handle zsh-specific cleanup
    if [ -n "$ZSH_VERSION" ]; then
        # Temporarily disable zsh autosuggestions
        _zsh_autosuggest_disable 2>/dev/null
        trap '_zsh_autosuggest_enable 2>/dev/null; unset _ANIMATE_RUNNING; return' EXIT INT TERM
    else
        trap 'unset _ANIMATE_RUNNING; return' EXIT INT TERM
    fi

    message="${1:-}"
    sleeptime="${2:-}"
    color="${3:-}"
    startat="${4:-1}"
    animate_msg="${5:-1}"

    # Accelerated delays
    delay=0.015
    dots_delay=0.03
    max_dots=3

    # Clear buffer and line completely
    clear_line
    printf "\r\033[K"
    
    printf "%b" "$color"
    if [ "$animate_msg" -eq 1 ]; then
        i="$startat"
        message_length=${#message}
        while [ "$i" -le "$message_length" ]; do
            printf "%b" "${message:$((i-1)):1}"
            sleep "$delay"
            i=$((i + 1))
        done
    else
        printf "%b" "$message"
    fi

    # Rest of animation remains unchanged
    end_time=$(echo "$(date +%s.%N) + $sleeptime" | bc)
    dot_count=0
    while [ "$(echo "$(date +%s.%N) < $end_time" | bc)" -eq 1 ]; do
        dots=""
        num_dots=$(((dot_count % max_dots) + 1))
        j=1
        while [ "$j" -le "$num_dots" ]; do
            dots="$dots."
            j=$((j + 1))
        done
        printf "\r\033[K%b%b%b%b" "$color" "$message" "$dots" "$RESET"
        sleep "$dots_delay"
        dot_count=$((dot_count + 1))
    done
    printf "\r\033[K%b%b\n" "$color" "mb environment reset. $RESET"

    # Re-enable zsh features if needed
    [ -n "$ZSH_VERSION" ] && _zsh_autosuggest_enable 2>/dev/null
    unset _ANIMATE_RUNNING
}

