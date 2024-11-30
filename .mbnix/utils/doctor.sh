#!/bin/bash
if [ -z "$_DOCTOR_MBNIX_RUNNING" ]; then
    export _DOCTOR_MBNIX_RUNNING=0
fi
if [ "$_DOCTOR_MBNIX_RUNNING" -eq 1 ]; then
    return
fi
export _DOCTOR_MBNIX_RUNNING=1
all_sources() {
  localhelp () {
    echo "Usage: all_sources [search_term]"
    echo "Searches all shell configuration files for aliases, exports, and sources."
    echo "If search_term is provided, only matching lines are shown."
  }
  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then localhelp; return; fi
    search_term="$1"
    files_list=$(mktemp)
    trap 'rm -f "$files_list"' EXIT

    # Find all relevant shell files
    find "${MB_WS:-$HOME/mbnix}" -type f \( -name "*.sh" -o -name ".zshrc" -o -name ".bashrc" \) > "$files_list"

    echo "=== Shell Configuration Analysis ==="
    [ -n "$search_term" ] && echo "Searching for: $search_term"
    echo

    # Process and filter files
    while IFS= read -r file; do
        awk -v file="$file" -v term="$search_term" '
        /^\s*(alias|export|source|\.)/ {
            # Skip if search term provided and line does not match
            if (term != "" && tolower($0) !~ tolower(term)) next

            if ($1 == "alias") {
                match($0, /alias[[:space:]]+([^=]+)=/, arr)
                if (arr[1]) {
                    key = "alias:" arr[1]
                    printf "%s\t%s:%d\t%s\n", key, file, NR, $0
                }
            }
            else if ($1 == "export") {
                match($0, /export[[:space:]]+([^=]+)=/, arr)
                if (arr[1]) {
                    key = "export:" arr[1]
                    printf "%s\t%s:%d\t%s\n", key, file, NR, $0
                }
            }
            else if ($1 == "source" || $1 == ".") {
                key = "source:" $2
                printf "%s\t%s:%d\t%s\n", key, file, NR, $0
            }
        }' "$file"
    done < "$files_list" | sort | awk '
    BEGIN {
        FS="\t"
        last_key=""
        count=0
    }
    {
        if ($1 != last_key) {
            if (count > 1) printf "\n"
            count = 1
            last_key = $1
            printf "\n=== %s ===\n", $1
        } else {
            count++
        }
        printf "  %s\n    %s\n", $2, $3
    }
    END {
        if (count > 1) printf "\n"
    }'

    echo -e "\nAnalysis complete. Entries shown multiple times indicate duplicates."
}





shell_doctor() {
    files_list=$(mktemp)
    trap 'rm -f "$files_list"' EXIT

    find "${MB_WS:-$HOME/mbnix}" -type f \( -name "*.sh" -o -name ".zshrc" -o -name ".bashrc" \) > "$files_list"

    echo "=== Duplicate Definitions Analysis ==="
    echo

    # Process files and track duplicates
    awk '
    function print_duplicates(arr, key) {
        if (length(arr[key]) > 1) {
            printf "\n=== %s ===\n", key
            for (loc in arr[key]) {
                printf "  %s\n", arr[key][loc]
            }
        }
    }

    BEGIN {
        FS="\t"
    }

    # Process file line by line
    FILENAME == ARGV[1] {
        file=$0
        while ((getline line < file) > 0) {
            if (line ~ /^\s*(alias|export|source|\.)/) {
                if (line ~ /^\s*alias/) {
                    match(line, /alias[[:space:]]+([^=]+)=/, arr)
                    if (arr[1]) {
                        key = "alias:" arr[1]
                        locations[key][FNR] = sprintf("%s:%d\n    %s", file, FNR, line)
                    }
                }
                else if (line ~ /^\s*export/) {
                    match(line, /export[[:space:]]+([^=]+)=/, arr)
                    if (arr[1]) {
                        key = "export:" arr[1]
                        locations[key][FNR] = sprintf("%s:%d\n    %s", file, FNR, line)
                    }
                }
                else if (line ~ /^\s*(source|\.)/) {
                    match(line, /(source|\.)[[:space:]]+([^[:space:]]+)/, arr)
                    if (arr[2]) {
                        key = "source:" arr[2]
                        locations[key][FNR] = sprintf("%s:%d\n    %s", file, FNR, line)
                    }
                }
            }
        }
        close(file)
    }

    END {
        for (key in locations) {
            print_duplicates(locations, key)
        }
        print "\nDuplicate Analysis Complete."
    }
    ' "$files_list"
}


alias doctor="shell_doctor" # Show duplicate definitions in shell configuration files.
alias allsources="all_sources" # List all sources, exports, and aliases in shell configuration files.
unset _DOCTOR_MBNIX_RUNNING