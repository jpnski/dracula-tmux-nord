#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

label=$1

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $current_dir/utils.sh

main() {
  RATE=$(get_tmux_option "@dracula-refresh-rate" 5)
  OUTPUT_STRING="N/A"
  if command -v terraform >/dev/null 2>&1; then
    current_workspace=$(terraform workspace show 2>/dev/null)
    OUTPUT_STRING="${current_workspace:-N/A}"
  fi
  if [ "$label" = "" ]
  then
      echo "⚙️ ${OUTPUT_STRING}"
  else
      echo "⚙️ ${label} ${OUTPUT_STRING}"
  fi

  sleep $RATE
}

# run the main driver
main
