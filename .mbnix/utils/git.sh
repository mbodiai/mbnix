#! /usr/bin/sh
if [ -n "$MB_GIT" ]; then
    echo "git already sourced. Run 'unset MB_GIT' to reload."
    return
fi
export MB_GIT="sourced"

git_search_term() {
    # Function to display usage/help message
    usage() {
        becho "Usage: git_search_term TERM -p PATH [-d] [-h] [-C CONTEXT]"
        becho
        becho "Search for a TERM in the file or folder across all commits in the repository (including diffs)."
        becho
        becho "Options:"
        becho "  -p PATH        Path to the file or folder to search within."
        becho "  -d             Search for the TERM in diffs (actual content changes)."
        becho "  -C CONTEXT     Number of context lines to display before/after each match (default is 3)."
        becho "  -h             Display this help message."
        becho
        becho "Examples:"
        becho "  git_search_term 'my_function' -p src/app.py           # Search in commit contents for the term 'my_function' in src/app.py"
        becho "  git_search_term 'my_function' -p src/ -d -C 5         # Search in diffs for the term 'my_function' with 5 lines of context"
    }

    # Parse the first argument as the search term
    search_term="$1"

    # Ensure search term is provided
    if [ -z "$search_term" ]; then
        git_list_diffs_last_commit
    fi

    # Set default values for search_path, search_in_diffs, and context lines
    search_path=$(realpath ".")
    context_lines=3 # Default number of context lines

    # Parse remaining options
    shift # Shift to process the remaining options
    while getopts ":p:C:h" opt; do
        case $opt in
        p) search_path=$(realpath "$OPTARG") ;;
        C) context_lines="$OPTARG" ;;
        h)
            usage
            return
            ;;
        \?)
           becho "Invalid option: -$OPTARG"
            usage
            return 1
            ;;
        esac
    done

    # Ensure the path is valid
    if [ ! -d "$search_path" ] && ! [ -f "$search_path" ]; then
        becho "Error: Invalid path '$search_path'."
        return 1
    fi

    # Perform the search
   becho "Searching for '$search_term' in diffs (actual content changes) for path '$search_path' with $context_lines lines of context..." | becho -
    git log --all -p -U"$context_lines" -S "$search_term" -- "$search_path" --date-order | $BAT --style=numbers --color=always --theme=1337 --highlight-line 1 -l python -
}
# Function to clean up a submodule and push it to a temporary branch
git_submodule_clean() {
    if [ -z "$1" ]; then
       becho "Usage: git_submodule_clean <submodule-path>"
        return 1
    fi

    submodule_path="$1"

    # Ensure the submodule exists
    if [ ! -d "$submodule_path" ]; then
       becho "Error: Submodule path '$submodule_path' does not exist."
        return 1
    fi

    # Get the submodule URL from .gitmodules
    submodule_url=$(git config --file .gitmodules --get submodule."$submodule_path".url)
    if [ -z "$submodule_url" ]; then
       becho "Error: Could not find URL for submodule '$submodule_path'."
        return 1
    fi
   becho "Submodule URL: $submodule_url"

    # Create a temporary branch to save the submodule
   becho "Pushing submodule '$submodule_path' to a temporary branch..."
    (cd "$submodule_path" && git checkout -b temp_submodule_branch && git push origin temp_submodule_branch)

    # Deinitialize the submodule
   becho "Deinitializing submodule '$submodule_path'..."
    git submodule deinit -f "$submodule_path"

    # Remove the submodule from the index and the .gitmodules file
   becho "Removing submodule '$submodule_path' from the index and .gitmodules..."
    git rm -f "$submodule_path"

    # Commit the changes to the main repo
    git commit -m "Removed submodule $submodule_path and saved it to a temp branch."

    # Remove the submodule entry from the .git/modules folder
   becho "Removing submodule cache from .git/modules..."
    rm -rf ".git/modules/$submodule_path"

    # Remove the submodule's working directory
   becho "Deleting submodule directory '$submodule_path'..."
    rm -rf "$submodule_path"

    # Save the submodule URL to a temporary file for reuse
   becho "Saving submodule URL..."
   becho "$submodule_url" >/tmp/"$submodule_path"_url.txt

   becho "Submodule '$submodule_path' cleaned successfully and saved to temp branch."
}

# Function to reinitialize submodules and pull the temporary branch back
git_submodule_reinit() {
    if [ -z "$1" ]; then
       becho "Usage: git_submodule_reinit <submodule-path>"
        return 1
    fi

    submodule_path="$1"

    # Reinitialize submodules
   becho "Reinitializing submodules..."
    git submodule init

    # Synchronize URLs for submodules
   becho "Synchronizing submodule URLs..."
    git submodule sync

    # Update submodules recursively
   becho "Updating submodules recursively..."
    git submodule update --init --recursive

    # Pull the submodule back from the temporary branch
   becho "Re-adding submodule '$submodule_path' from temp branch..."

    # Get the saved submodule URL from the temp file
    submodule_url=$(cat /tmp/"$submodule_path"_url.txt)
    if [ -z "$submodule_url" ]; then
       becho "Error: Could not find saved URL for submodule '$submodule_path'."
        return 1
    fi
   becho "Submodule URL: $submodule_url"

    git submodule add "$submodule_url" "$submodule_path"
    (cd "$submodule_path" && git checkout temp_submodule_branch)

    # Commit the changes to the main repo
    git add .gitmodules "$submodule_path"
    git commit -m "Re-added submodule $submodule_path from temp branch."

   becho "Submodule '$submodule_path' reinitialized successfully from temp branch."
}
gsub_make() {
    if [ -z "$1" ]; then
       becho "Usage: gsub <submodule-path>"
        return 1
    fi

    git_submodule_clean "$1"
    git_submodule_reinit "$@"
}
# Function to update and push each submodule to a temporary branch
git_push_temp() {
    # Update submodules and ensure they are at the latest commit
    git submodule update --recursive --remote

    # Iterate over all submodules
    git submodule foreach "
        # Create a temporary branch inside the submodule
        branch_name="temp_submodule_branch_\"$(tfmt +%s)\"
       becho "Creating and pushing to branch $branch_name for submodule $name...\"
        git checkout -b \"$branch_name\"

        # Add all changes and commit
        git add .
        git commit -m "Updated submodule $name on temporary branch $branch_name"

        # Push the temporary branch to the remote
        git push origin \"$branch_name\"

        # Return to the original branch
        git checkout -
    "

   becho "Submodules updated and pushed to temporary branches."
}


git_list_diffs_last_commit() {

    # Show filenames with their corresponding commit timestamps, including submodules
   becho "Filename: Date (sorted by timestamp, including submodules):"

    # Fetch logs with filenames and submodule changes, format and sort by timestamp
    git log --submodule --name-only --pretty=format:"%ad" --date=iso |
        awk '/^[0-9]{4}/ {date=$0; next} NF {print date " " $0}' | sort |
        $BAT --style=numbers --color=always --theme=1337 --highlight-line 1 -l python -
   becho
    for branch in $(git for-each-ref --sort=-committerdate --format='%(refname:short)' refs/heads/ refs/remotes/); do
        timestamp=$(git log -1 --format="%ci" "$branch" | tfmt)
       becho "$timestamp - $branch" 
    done
}

alias gpt='git_push_temp' # Update and push each submodule to a temporary branch
alias gld='git_list_diffs_last_commit' # List filenames with their corresponding commit timestamps
alias gs='git_search_term' # Search for a term in the file or folder across all commits in the repository
alias gsr='git_submodule_reinit' # Reinitialize submodules and pull the temporary branch back
alias gsub='gsub_make' # Clean and reinitialize a submodule
alias gsc='git_submodule_clean' # Clean a submodule and push it to a temporary branch
alias gdc='git diff --compact-summary' # Show a compact summary of changes