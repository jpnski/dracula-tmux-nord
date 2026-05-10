#!/usr/bin/env bash

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $current_dir/utils.sh

IFS=' ' read -r -a hide_status <<< $(get_tmux_option "@dracula-git-disable-status" "false")
IFS=' ' read -r -a current_symbol <<< $(get_tmux_option "@dracula-git-show-current-symbol" "✓")
IFS=' ' read -r -a diff_symbol <<< $(get_tmux_option "@dracula-git-show-diff-symbol" "!")
IFS=' ' read -r -a no_repo_message <<< $(get_tmux_option "@dracula-git-no-repo-message" "")
IFS=' ' read -r -a no_untracked_files <<< $(get_tmux_option "@dracula-git-no-untracked-files" "false")
IFS=' ' read -r -a show_remote_status <<< $(get_tmux_option "@dracula-git-show-remote-status" "false")
show_repo_name="$(get_tmux_option "@dracula-git-show-repo-name" "false")"
git_truncate_length="$(get_tmux_option "@dracula-git-truncate-length" "")"

GIT_DIR=""

getChanges()
{
    local added=0
    local modified=0
    local updated=0
    local deleted=0

    local git_out
    git_out=$(git --git-dir="$GIT_DIR" --no-optional-locks status -s 2>/dev/null)
    [ -z "$git_out" ] && echo "" && return

    for i in $git_out
    do
      case $i in
      'A') added=$((added + 1)) ;;
      'M') modified=$((modified + 1)) ;;
      'U') updated=$((updated + 1)) ;;
      'D') deleted=$((deleted + 1)) ;;
      esac
    done

    local output=""
    [ $added -gt 0 ] && output+="${added}A"
    [ $modified -gt 0 ] && output+=" ${modified}M"
    [ $updated -gt 0 ] && output+=" ${updated}U"
    [ $deleted -gt 0 ] && output+=" ${deleted}D"

    echo $output
}

getPaneDir()
{
    local pane_path=""
    local nextone="false"
    while IFS=$'\t' read -r active path; do
        if [ "$nextone" == "true" ]; then
            pane_path="$path"
            break
        fi
        if [ "$active" == "1" ]; then
            nextone="true"
        fi
    done < <(tmux list-panes -F "#{pane_active}	#{pane_current_path}" 2>/dev/null)
    sanitize_git_path "$pane_path"
}

checkForGitDir()
{
    [ -n "$GIT_DIR" ] && [ -d "$GIT_DIR" ] && [ -r "$GIT_DIR/HEAD" ] && echo "true" || echo "false"
}

checkForChanges()
{
    [ "$no_untracked_files" == "false" ] && no_untracked="" || no_untracked="-uno"
    if [ "$(checkForGitDir)" == "true" ]; then
        if [ "$(git --git-dir="$GIT_DIR" --no-optional-locks status -s $no_untracked 2>/dev/null)" != "" ]; then
            echo "true"
        else
            echo "false"
        fi
    else
        echo "false"
    fi
}

getBranch()
{
    if [ "$(checkForGitDir)" == "true" ]; then
        echo "$(git --git-dir="$GIT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    else
        echo "$no_repo_message"
    fi
}

getRemoteInfo()
{
    local head_ref
    head_ref=$(git --git-dir="$GIT_DIR" symbolic-ref -q HEAD 2>/dev/null)
    [ -z "$head_ref" ] && echo "" && return

    local base
    base=$(git --git-dir="$GIT_DIR" for-each-ref --format='%(upstream:short) %(upstream:track)' "$head_ref" 2>/dev/null)
    [ -z "$base" ] && echo "" && return

    local remote
    remote=$(echo "$base" | awk '{print $1}')
    local out=""

    if [ -n "$remote" ]; then
        out="...$remote"
        local ahead behind
        ahead=$(echo "$base" | grep -Eo 'ahead[[:space:]]+[[:digit:]]+' | awk '{print $2}')
        behind=$(echo "$base" | grep -Eo 'behind[[:space:]]+[[:digit:]]+' | awk '{print $2}')
        [ -n "$ahead" ] && out+=" +$ahead"
        [ -n "$behind" ] && out+=" -$behind"
    fi

    echo "$out"
}

getRepoName()
{
    if [ "$show_repo_name" = "true" ] && [ "$(checkForGitDir)" = "true" ]; then
        local repo
        repo="$(git --git-dir="$GIT_DIR" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)"
        repo="$(basename "$repo")"
        echo "$repo | "
    fi
}

# check if the current or diff symbol is empty to remove ugly padding
checkEmptySymbol()
{
    symbol=$1    
    if [ "$symbol" == "" ]; then
        echo "true"
    else
        echo "false"
    fi
}

# return the final message for the status bar
getMessage()
{
    if [ $(checkForGitDir) == "true" ]; then
        branch="$(getBranch)"
        [ -n "$git_truncate_length" ] && branch="${branch:0:$git_truncate_length}"
        repo_name="$(getRepoName)"
        output=""

        if [ $(checkForChanges) == "true" ]; then 
            
            changes="$(getChanges)" 
            
            if [ "${hide_status}" == "false" ]; then
               if [ "$(checkEmptySymbol "${diff_symbol[0]}")" = "true" ]; then
		     output="$repo_name${changes:+ ${changes}} $branch"
                else
		     output="$repo_name${diff_symbol[0]} ${changes:+$changes }$branch"
                fi
            else
               if [ "$(checkEmptySymbol "${diff_symbol[0]}")" = "true" ]; then
		     output=$(echo "$repo_name$branch")
                else
		     output=$(echo "$repo_name$diff_symbol $branch")
                fi
            fi

        else
            if [ $(checkEmptySymbol $current_symbol) == "true" ]; then
	         output=$(echo "$repo_name$branch")
            else
		      output="$repo_name${current_symbol[0]} $branch"
            fi
        fi

        [ "$show_remote_status" == "true" ] && output+=$(getRemoteInfo)
        echo "$output"
    else
        echo $no_repo_message
    fi
}

main()
{
    local pane_path
    pane_path=$(getPaneDir)
    if [ -n "$pane_path" ]; then
        GIT_DIR="$(cd "$pane_path/.git" 2>/dev/null && pwd)"
    fi
    getMessage
}

#run main driver program
main 
