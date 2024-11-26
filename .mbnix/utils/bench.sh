#!/bin/sh

if [ -n "$MB_BENCH" ]; then
    echo "Benchmark already sourced. Run 'unset MB_BENCH' to reload."
    return
fi
export MB_BENCH="sourced"

benchmark_scripts() {
     results_file="/tmp/shell_benchmark.txt"
     script_list="/tmp/shell_scripts.txt"
     total=0
    
    # Clear previous results
    echo "Shell Script Benchmark Results" > "$results_file"
    date >> "$results_file"
    echo "-------------------------" >> "$results_file"

    # Cache script list
    find "${MB_WS:-$HOME/mbnix}" -type f \( -name "*.sh" -o -name ".zshrc" -o -name ".bashrc" \) > "$script_list"
    total=$(wc -l < "$script_list")

    echo "Benchmarking $total scripts..."

    # Benchmark each script in isolated subprocess
    while IFS= read -r script; do
        duration=$( (bash -c '
            # Save original env
            declare -p > /tmp/orig_env.sh
            
            # Source script and measure time
            TIMEFORMAT="%R"
            time source "$1" >/dev/null 2>&1
            
            # Restore original env
            source /tmp/orig_env.sh
        ' bash "$script") 2>&1 )
        
        printf "%-60s: %6.3f seconds\n" "$(basename "$script")" "$duration" >> "$results_file"
    done < "$script_list"

    # Format and display results
    echo "Top 10 slowest scripts:"
    echo "-------------------------"
    sort -k3 -nr "$results_file" | grep "seconds" | head -n 10 | \
        awk '{printf "%-40s %8.3f seconds\n", $1, $3}'
    
    rm "$script_list"
    rm -f /tmp/orig_env.sh
}

alias bench="benchmark_scripts"
