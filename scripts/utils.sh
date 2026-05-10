#!/usr/bin/env bash

get_tmux_option() {
  local option="$1"
  local default_value="$2"
  local option_value="$(tmux show-option -gqv "$option")"
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

get_tmux_window_option() {
  local option="$1"
  local default_value="$2"
  local option_value="$(tmux show-window-options -v "$option")"
  if [ -z "$option_value" ]; then
    echo "$default_value"
  else
    echo "$option_value"
  fi
}

# normalize the percentage string to always have a length of 5
normalize_percent_len() {
  max_len=5
  percent_len=${#1}
  let diff_len=$max_len-$percent_len
  let left_spaces=($diff_len+1)/2
  let right_spaces=($diff_len)/2
  printf "%${left_spaces}s%s%${right_spaces}s\n" "" $1 ""
}

sanitize_git_path() {
  local path="$1"
  case "$path" in
    -*|--*) echo ""; return ;;
  esac
  local abs_path="$(cd "$path" 2>/dev/null && pwd)"
  echo "$abs_path"
}

escape_awk_regex() {
  local str="$1"
  printf '%s' "$str" | sed 's/[][().*+?^${}|/\-]/\\&/g'
}

