#!/bin/sh


# Function t: Lists the directory tree or searches file contents with pass-through for additional args
treecmd() {
    show_help() {
        printf "Usage: t [-t|--timestamps] [@|DEPTH] [DIR] [TERM] [-h|--help]\n" | ${BAT:-cat} -
    }
    
    ensure_cmd() {
        command -v "$1" >/dev/null 2>&1 || { echo "Required: $1" >&2; return 1; }
    }

    ensure_cmd "tree" || return 1
    
    show_time=false
    depth=2
    dir="."
    term=""
    extra_args="$*"

    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                return
                ;;
            -t|--timestamps)
                show_time=true
                shift
                ;;
            @)
                depth=2
                shift
                ;;
            [0-9]*)
                depth=$1
                shift
                ;;
            *)
                if [ -d "$1" ]; then
                    dir=$1
                elif [ -n "$1" ]; then
                    term=$1
                fi
                shift
                ;;
        esac
    done

    if [ -n "$term" ]; then
        ensure_cmd "rg" || return 1
        rg --with-filename -C 1 "$term" "$dir"
    else
        cmd="tree -I '__pycache__|*.pyc|*.pyo' -L $depth --dirsfirst -C"
         [ "$show_time" = true ] && cmd="$cmd -D --timefmt='%B %d %Y %T'"
        eval "$cmd \"$dir\" ${extra_args}"
    fi
}

# Cleans up pyc files and searches for term in specific file types with timestamps
tsearch() {
    FILE_TYPES="*.py *.sh *.md *.toml"
    FILE_LINES=50
    display_timestamps=false
    TERM_SEARCH=""
    ignore_file=""
    setup_environment() {
        ensure_dependency "rg" "ripgrep"
        [ -z "$BAT" ] && echo "Note: 'bat' is not installed. Using 'cat' instead."
        ignore_file=$(mktemp)
        printf '__pycache__\n*.pyc\n*.pyo\n' > "$ignore_file"
        trap cleanup EXIT INT TERM
    }

    cleanup() {
        rm -f "$ignore_file"
    }

   

    show_help() {
        printf "Usage: ts [term] [--tests] [--timestamps]\nOptions:\n    term        A search term to look for within the specified file types (${FILE_TYPES}).\n                Displays a summary of up to ${FILE_LINES} lines.\n    --tests     Include test files (files in 'tests/' directories or prefixed with 'test_').\n    --timestamps Display the modification time for each file.\n    --help, -h  Show this help message.\n" | ${BAT:-cat} -
    }

    clean_python_files() {
        ensure_dependency "pyclean" "clean"
        pyclean -e "**/*.pyc" --yes . && pyclean -e "**/__pycache__" --yes .
    }

    find_files() {
        pattern="$1"
        find . -type f "$pattern" \
            -not -path "*/__pycache__/*" \
            -not -name "*.pyc" \
            -not -name "*.pyo"
    }

    preview_matching_files() {
        while read -r file && [ "$printed_lines" -lt "$FILE_LINES" ]; do
            preview_file "$file" 5
        done
    }

    process_files() {
        mode="$1"
        case "$mode" in
            "tests")
                find_files "( -name 'test_*.py' -o -path '*/tests/*.py' )" | 
                    preview_matching_files
                ;;
            "all")
                find_files "( -name '*.py' -o -name '*.sh' -o -name '*.md' -o -name '*.toml' )" |
                    preview_matching_files
                ;;
            "search")
                rg --files-with-matches "$TERM_SEARCH" \
                    --glob '*.py' --glob '*.sh' --glob '*.md' --glob '*.toml' \
                    --ignore-file "$ignore_file" |
                    grep -E '\.(py|sh|md|toml)$' |
                    preview_matching_files ||
                    printf "No matches found for term '%s'.\n" "$TERM_SEARCH" | ${BAT:-cat} -
                ;;
        esac
    }

    # Parse options
    while [ "$#" -gt 0 ] && [ "$1" != "${1#-}" ]; do
        case "$1" in
            --timestamps) display_timestamps=true; shift ;;
            --help|-h) show_help; return ;;
            *) printf "Unknown option: %s\n" "$1" | ${BAT:-cat} -; return 1 ;;
        esac
    done

    TERM_SEARCH="$1"
    setup_environment
    clean_python_files

    if [ "$TERM_SEARCH" = "--tests" ]; then
        echo "Including test files..."
        process_files "tests"
    elif [ -z "$TERM_SEARCH" ]; then
        echo "Searching for all files of specified types..."
        process_files "all"
    else
        echo "Searching for term '$TERM_SEARCH' in files matching ${FILE_TYPES}..."
        process_files "search"
    fi
}

# Shows changes with option for displaying timestamps
tgit() {
    FILE_LINES=50
    printed_lines=0
    display_timestamps=false

    # Ensure dependencies are installed
    ensure_dependency "git" "git"

    # Determine the appropriate bat command
    if [ -z "$BAT" ]; then
        echo "Note: 'bat' is not installed. Using 'cat' instead."
    fi

    # Parse options
    while [ $# -gt 0 ]; do
        case "$1" in
            --timestamps|-t)
                display_timestamps=true
                shift
                ;;
            --help|-h)
                printf "Usage: tgit [--timestamps]\nOptions:\n    --timestamps    Display the modification time for each changed file.\n    --help, -h      Show this help message.\n" | ${BAT:-cat} -
                return
                ;;
            *)
                printf "Unknown option: %s\n" "$1" | ${BAT:-cat} -
                return 1
                ;;
        esac
    done

    # Function to handle file diffs
    handle_diff() {
        file="$1"
        if [ "$printed_lines" -ge "$FILE_LINES" ]; then
            return
        fi
        if [ -f "$file" ]; then
            echo "File: $file"
            if [ "$display_timestamps" = true ]; then
                get_mod_time "$file"
            fi
            git diff HEAD~1 HEAD -- "$file" | if [ -n "$BAT" ]; then
                $BAT --paging=never
            else
                cat
            fi || echo "Error displaying diff for file: $file"
            printed_lines=$((printed_lines + 5))
            echo
        fi
    }

    echo "Files changed in the last commit:"
    git diff --name-only HEAD~1 HEAD | while read -r file; do
        handle_diff "$file"
    done

    echo "Files with uncommitted changes:"
    git diff --name-only | while read -r file; do
        handle_diff "$file"
    done
}

alias t='treecmd'
alias ts='tsearch'
alias tg='tgit'
