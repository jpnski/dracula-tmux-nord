#!/usr/bin/env bash

# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $current_dir/utils.sh

show_ssh_session_port=$1

parse_ssh_port() {
  # Get port from connection
  local port=$(echo $1|grep -Eo '\-p\s*([0-9]+)'|sed 's/-p\s*//')

  if [ -z $port ]; then
    local port=22
  fi

  echo $port
}

parse_ssh_config() {
  for ssh_config in `awk '
    $1 == "Host" {
      gsub("\\\\.", "\\\\.", $2);
      gsub("\\*", ".*", $2);
      host = $2;
      next;
    }
    $1 == "User" {
      $1 = "";
      sub( /^[[:space:]]*/, "" );
      printf "%s|%s\n", host, $0;
    }' $1`; do
    local host_regex=${ssh_config%|*}
    local host_user=${ssh_config#*|}
    if [ "$2" == "$host_regex" ]; then
      ssh_user_found=$host_user
      break
    fi
  done

  echo $ssh_user_found
}

get_ssh_user() {
  # Search SSH User in user local file if available
  if [ -f ~/.ssh/config ]; then
    ssh_user=$(parse_ssh_config ~/.ssh/config $1)
  fi

  # If SSH User not found, search in global config file
  if [ -z $ssh_user ]; then
    ssh_user=$(parse_ssh_config /etc/ssh/ssh_config $1)
  fi

  #If SSH User not found in any config file, return current user
  if [ -z $ssh_user ]; then
    ssh_user=$(whoami)
  fi

  echo $ssh_user
}

get_remote_info() {
  local pane_pid=$(tmux display-message -p "#{pane_pid}")
  local cmd=""
  for pid in $(pgrep -P "$pane_pid" 2>/dev/null); do
    local proc_cmd=$(ps -o command= -p "$pid" 2>/dev/null)
    if echo "$proc_cmd" | grep -q "ssh "; then
      cmd="$proc_cmd"
      break
    fi
  done
  if [ -z "$cmd" ]; then
    cmd=$(ps -o command= -p "$pane_pid" 2>/dev/null)
  fi

  local port=$(parse_ssh_port "$cmd")
  cmd=$(echo $cmd | sed 's/\-p\s*'"$port"'//g')

  local target=""
  for arg in $cmd; do
    if [ "$arg" != "ssh" ] && [[ "$arg" != -* ]]; then
      target="$arg"
    fi
  done

  local user=""
  local host="$target"
  if echo "$target" | grep -q "@"; then
    local user_host_pair="$target"
    local user="${user_host_pair%@*}"
    local host="${user_host_pair#*@}"
  fi

  if [ -z "$user" ] || [ "$user" == "$host" ]; then
    user=$(get_ssh_user "$host")
  fi

  case "$1" in
    "whoami")
      echo $user
      ;;
    "hostname")
      echo $host
      ;;
    "port")
      echo $port
      ;;
    *)
      echo "$user@$host:$port"
      ;;
  esac
}

get_info() {
  # If command is ssh get info from remote
  if $(ssh_connected); then
    echo $(get_remote_info $1)
  else
    echo $($1)
  fi
}

ssh_connected() {
  # Get current pane command
  local cmd=$(tmux display-message -p "#{pane_current_command}")

  [ $cmd = "ssh" ] || [ $cmd = "sshpass" ]
}

main() {
  hostname=$(get_info hostname)
  user=$(get_info whoami)

  # Only show port info if ssh session connected (no localhost) and option enabled
  if $(get_tmux_option "@dracula-show-ssh-only-when-connected" false) && ! $(ssh_connected); then
    echo ""
  elif $(ssh_connected) && [ "$show_ssh_session_port" == "true" ] ; then
    port=$(get_info port)
    echo $user@$hostname:$port
  else
    echo $user@$hostname
  fi
}

main
