#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $current_dir/utils.sh

# Resolve a color variable name to its hex value, or pass through raw hex values
resolve_color() {
  local name="$1"
  if [[ "$name" == \#* ]]; then
    echo "$name"
  else
    echo "${!name}"
  fi
}

main() {
  # set configuration option variables
  show_krbtgt_label=$(get_tmux_option "@dracula-krbtgt-context-label" "")
  krbtgt_principal=$(get_tmux_option "@dracula-krbtgt-principal" "")
  show_kubernetes_context_label=$(get_tmux_option "@dracula-kubernetes-context-label" "")
  show_only_kubernetes_context=$(get_tmux_option "@dracula-show-only-kubernetes-context" false)
  eks_hide_arn=$(get_tmux_option "@dracula-kubernetes-eks-hide-arn" false)
  eks_extract_account=$(get_tmux_option "@dracula-kubernetes-eks-extract-account" false)
  hide_kubernetes_user=$(get_tmux_option "@dracula-kubernetes-hide-user" false)
  terraform_label=$(get_tmux_option "@dracula-terraform-label" "")
  show_powerline=$(get_tmux_option "@dracula-show-powerline" false)
  transparent_powerline_bg=$(get_tmux_option "@dracula-transparent-powerline-bg" false)
  show_flags=$(get_tmux_option "@dracula-show-flags" false)
  show_left_icon=$(get_tmux_option "@dracula-show-left-icon" smiley)
  show_left_icon_padding=$(get_tmux_option "@dracula-left-icon-padding" 1)
  show_left_sep=$(get_tmux_option "@dracula-show-left-sep" )
  show_right_sep=$(get_tmux_option "@dracula-show-right-sep" )
  show_edge_icons=$(get_tmux_option "@dracula-show-edge-icons" false)
  show_inverse_divider=$(get_tmux_option "@dracula-inverse-divider" )
  show_border_contrast=$(get_tmux_option "@dracula-border-contrast" false)
  show_refresh=$(get_tmux_option "@dracula-refresh-rate" 5)
  show_synchronize_panes_label=$(get_tmux_option "@dracula-synchronize-panes-label" "Sync")
  show_empty_plugins=$(get_tmux_option "@dracula-show-empty-plugins" true)
  left_pad=$(get_tmux_option "@dracula-left-pad" " ")
  right_pad=$(get_tmux_option "@dracula-right-pad" " ")

  if [ "$left_pad" = false ]; then left_pad=""; fi
  if [ "$right_pad" = false ]; then right_pad=""; fi

  IFS=' ' read -r -a plugins <<< $(get_tmux_option "@dracula-plugins" "git cpu-usage ram-usage")

  # Dracula Color Pallette
  white="#f8f8f2"
  gray="#44475a"
  dark_gray="#282a36"
  light_purple="#bd93f9"
  dark_purple="#6272a4"
  cyan="#8be9fd"
  green="#50fa7b"
  orange="#ffb86c"
  red="#ff5555"
  purple="#b166cc"
  pink="#ff79c6"
  yellow="#f1fa8c"

  # Override default colors and possibly add more
  colors="$(get_tmux_option "@dracula-colors" "")"
  if [ -n "$colors" ]; then
    eval "$colors"
  fi

  # Resolve theme element color overrides (users set variable names, not hex values)
  left_icon_bg=$(resolve_color "$(get_tmux_option "@dracula-left-icon-bg" "green")")
  left_icon_fg=$(resolve_color "$(get_tmux_option "@dracula-left-icon-fg" "dark_gray")")
  left_icon_prefix_bg=$(resolve_color "$(get_tmux_option "@dracula-left-icon-prefix-bg" "yellow")")
  left_icon_prefix_fg=$(resolve_color "$(get_tmux_option "@dracula-left-icon-prefix-fg" "dark_gray")")
  active_window_bg=$(resolve_color "$(get_tmux_option "@dracula-active-window-bg" "dark_purple")")
  active_window_fg=$(resolve_color "$(get_tmux_option "@dracula-active-window-fg" "white")")
  inactive_window_fg=$(resolve_color "$(get_tmux_option "@dracula-inactive-window-fg" "white")")
  flags_inactive_fg=$(resolve_color "$(get_tmux_option "@dracula-flags-inactive-fg" "dark_purple")")
  flags_active_fg=$(resolve_color "$(get_tmux_option "@dracula-flags-active-fg" "light_purple")")
  powerline_bg=$(resolve_color "$(get_tmux_option "@dracula-powerline-bg" "gray")")
  inactive_window_bg_name=$(get_tmux_option "@dracula-inactive-window-bg" "")

  # Set transparency variables - Colors and window dividers
  if $transparent_powerline_bg; then
	bg_color="default"
	if $show_edge_icons; then
	  window_sep_fg=${active_window_bg}
	  window_sep_bg=default
	  window_sep="$show_right_sep"
	else
	  window_sep_fg=${active_window_bg}
	  window_sep_bg=default
	  window_sep="$show_inverse_divider"
	fi
  else
    bg_color=${powerline_bg}
    if $show_edge_icons; then
      window_sep_fg=${active_window_bg}
      window_sep_bg=${powerline_bg}
      window_sep="$show_inverse_divider"
    else
      window_sep_fg=${powerline_bg}
      window_sep_bg=${active_window_bg}
      window_sep="$show_left_sep"
    fi
  fi

  # Resolve inactive window bg after bg_color is computed, so it falls back to bg_color
  if [ -n "$inactive_window_bg_name" ]; then
    inactive_window_bg=$(resolve_color "$inactive_window_bg_name")
  else
    inactive_window_bg=${bg_color}
  fi

  # Handle left icon configuration
  case $show_left_icon in
    smiley)
      left_icon="☺";;
    session)
      left_icon="#S";;
    window)
      left_icon="#W";;
    hostname)
      left_icon="#H";;
    shortname)
      left_icon="#h";;
    *)
      left_icon=$show_left_icon;;
  esac

  # Handle left icon padding
  padding=""
  if [ "$show_left_icon_padding" -gt "0" ]; then
    padding="$(printf '%*s' $show_left_icon_padding)"
  fi
  left_icon="$left_icon$padding"

  # Handle powerline option
  if $show_powerline; then
    right_sep="$show_right_sep"
    left_sep="$show_left_sep"
  fi

  case $show_flags in
    false)
      flags=""
      current_flags="";;
    true)
      flags="#{?window_flags,#[fg=${flags_inactive_fg}]#{window_flags},}"
      current_flags="#{?window_flags,#[fg=${flags_active_fg}]#{window_flags},}"
  esac

  # sets refresh interval to every 5 seconds
  tmux set-option -g status-interval $show_refresh

  # set length
  tmux set-option -g status-left-length 100
  tmux set-option -g status-right-length 100

  # pane border styling
  if $show_border_contrast; then
    tmux set-option -g pane-active-border-style "fg=${light_purple}"
  else
    tmux set-option -g pane-active-border-style "fg=${dark_purple}"
  fi
  tmux set-option -g pane-border-style "fg=${gray}"

  # message styling
  tmux set-option -g message-style "bg=${gray},fg=${white}"

  # status bar
  tmux set-option -g status-style "bg=${bg_color},fg=${white}"

  # Status left
  if $show_powerline; then
    if $show_edge_icons; then
      tmux set-option -g status-left "#[bg=${bg_color}]#[fg=${left_icon_bg}]#[bold]#{?client_prefix,#[fg=${left_icon_prefix_bg}],}${show_right_sep}#[bg=${left_icon_bg}]#[fg=${left_icon_fg}]#{?client_prefix,#[bg=${left_icon_prefix_bg}]#[fg=${left_icon_prefix_fg}],} ${left_icon} #[fg=${left_icon_bg}]#[bg=${bg_color}]#{?client_prefix,#[fg=${left_icon_prefix_bg}],}${left_sep} "
    else
      tmux set-option -g status-left "#[bg=${dark_gray}]#[fg=${left_icon_bg}]#[bg=${left_icon_bg}]#[fg=${left_icon_fg}]#{?client_prefix,#[bg=${left_icon_prefix_bg}]#[fg=${left_icon_prefix_fg}],} ${left_icon} #[fg=${left_icon_bg}]#[bg=${bg_color}]#{?client_prefix,#[fg=${left_icon_prefix_bg}],}${left_sep}"
    fi
    powerbg=${bg_color}
  else
    tmux set-option -g status-left "#[bg=${left_icon_bg}]#[fg=${left_icon_fg}]#{?client_prefix,#[bg=${left_icon_prefix_bg}]#[fg=${left_icon_prefix_fg}],} ${left_icon}"
  fi

  # Status right
  tmux set-option -g status-right ""

  for plugin in "${plugins[@]}"; do

    if case $plugin in custom:*) true;; *) false;; esac; then
      script=${plugin#"custom:"}
      if [[ -x "${current_dir}/${script}" ]]; then
        IFS=' ' read -r -a colors <<<$(get_tmux_option "@dracula-custom-plugin-colors" "cyan dark_gray")
        script="#($current_dir/${script})"
      else
        colors[0]="red"
        colors[1]="dark_gray"
        script="${script} not found!"
      fi

    elif [ $plugin = "git" ]; then
      IFS=' ' read -r -a colors  <<< $(get_tmux_option "@dracula-git-colors" "green dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/git.sh)"

    elif [ $plugin = "gpu-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-gpu-usage-colors" "pink dark_gray")
      script="#($current_dir/gpu_usage.sh)"

    elif [ $plugin = "gpu-ram-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-gpu-ram-usage-colors" "cyan dark_gray")
      script="#($current_dir/gpu_ram_info.sh)"

    elif [ $plugin = "cpu-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-cpu-usage-colors" "orange dark_gray")
      script="#($current_dir/cpu_info.sh)"

    elif [ $plugin = "ram-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-ram-usage-colors" "cyan dark_gray")
      script="#($current_dir/ram_info.sh)"

    elif [ $plugin = "attached-clients" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@dracula-attached-clients-colors" "cyan dark_gray")
      script="#($current_dir/attached_clients.sh)"

    elif [ $plugin = "krbtgt" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@dracula-krbtgt-colors" "cyan dark_gray")
      script="#($current_dir/krbtgt.sh $krbtgt_principal $show_krbtgt_label)"

    elif [ $plugin = "kubernetes-context" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@dracula-kubernetes-context-colors" "cyan dark_gray")
      script="#($current_dir/kubernetes_context.sh $eks_hide_arn $eks_extract_account $hide_kubernetes_user $show_only_kubernetes_context $show_kubernetes_context_label)"

    elif [ $plugin = "terraform" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@dracula-terraform-colors" "light_purple dark_gray")
      script="#($current_dir/terraform.sh $terraform_label)"

    elif [ $plugin = "continuum" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-continuum-colors" "cyan dark_gray")
      script="#($current_dir/continuum.sh)"

    elif [ $plugin = "synchronize-panes" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-synchronize-panes-colors" "cyan dark_gray")
      script="#($current_dir/synchronize_panes.sh $show_synchronize_panes_label)"

    elif [ $plugin = "uptime" ]; then
      IFS=$' ' read -r -a colors <<< $(get_tmux_option "@dracula-uptime-colors" "default default")
      script="#($current_dir/uptime.sh)"

    else
      continue
    fi

    # edge styling
    if $show_edge_icons; then
      right_edge_icon="#[bg=${bg_color}]#[fg=${!colors[0]}]${show_left_sep}"
      background_color=${bg_color}
    else
      background_color=${powerbg}
    fi

    # padding
    pad_script="$left_pad$script$right_pad"

    if $show_powerline; then
      if $show_empty_plugins; then
        tmux set-option -ga status-right " #[fg=${!colors[0]}]#[bg=${background_color}]#[nobold]#[nounderscore]#[noitalics]${right_sep}#[fg=${!colors[1]}]#[bg=${!colors[0]}]$pad_script$right_edge_icon"
      else
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[0]}]#[nobold]#[nounderscore]#[noitalics]${right_sep}#[fg=${!colors[1]}]#[bg=${!colors[0]}]$pad_script$right_edge_icon}"
    fi
      powerbg=${!colors[0]}
    else
      if $show_empty_plugins; then
        tmux set-option -ga status-right "#[fg=${!colors[1]}]#[bg=${!colors[0]}]$pad_script"
      else
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[1]}]#[bg=${!colors[0]}]$pad_script}"
      fi
    fi

  done

  # Window bell configuration
  window_bell=$(get_tmux_option "@dracula-window-bell" false)
  if [ "$window_bell" = "true" ]; then
    window_bell_blink=$(get_tmux_option "@dracula-window-bell-blink" true)
    window_bell_fg=$(resolve_color "$(get_tmux_option "@dracula-window-bell-fg" "dark_gray")")
    window_bell_bg=$(resolve_color "$(get_tmux_option "@dracula-window-bell-bg" "yellow")")

    # Build bell-aware flags
    case $show_flags in
      true)  bell_flags="#{?window_flags,#[fg=${window_bell_fg}]#{window_flags},}";;
      *)     bell_flags="";;
    esac

    if [ "$window_bell_blink" = "true" ]; then
      blink_on="#[blink]"
      blink_off="#[noblink]"
    else
      blink_on=""
      blink_off=""
    fi

    tmux set-option -g bell-action other
    tmux set-option -g monitor-bell on
    tmux set-option -g visual-bell off
  fi

  # Window option
  if $show_powerline; then
    tmux set-window-option -g window-status-current-format "#[fg=${window_sep_fg}]#[bg=${window_sep_bg}]${window_sep}#[fg=${active_window_fg}]#[bg=${active_window_bg}] #I #W${current_flags} #[fg=${active_window_bg}]#[bg=${bg_color}]${left_sep}"

    if [ "${inactive_window_bg}" != "${bg_color}" ]; then
      # Custom inactive bg: add powerline separators so inactive windows get the same chevron shape as active windows
      tmux set-window-option -g window-status-separator ""
      normal_fmt="#[fg=${bg_color}]#[bg=${inactive_window_bg}]${left_sep}#[fg=${inactive_window_fg}]#[bg=${inactive_window_bg}] #I #W${flags} #[fg=${inactive_window_bg}]#[bg=${bg_color}]${left_sep}"
      if [ "$window_bell" = "true" ]; then
        bell_fmt="#[fg=${bg_color}]#[bg=${window_bell_bg}]${left_sep}#[fg=${window_bell_fg}]#[bg=${window_bell_bg}]${blink_on} #I #W${bell_flags} #[fg=${window_bell_bg}]#[bg=${bg_color}]${blink_off}${left_sep}"
        tmux set-window-option -g window-status-format "#{?window_bell_flag,${bell_fmt},${normal_fmt}}"
      else
        tmux set-window-option -g window-status-format "${normal_fmt}"
      fi
    else
      normal_fmt="#[fg=${inactive_window_fg}]#[bg=${inactive_window_bg}] #I #W${flags}"
      if [ "$window_bell" = "true" ]; then
        bell_fmt="#[fg=${window_bell_fg}]#[bg=${window_bell_bg}]${blink_on} #I #W${bell_flags}${blink_off}"
        tmux set-window-option -g window-status-format "#{?window_bell_flag,${bell_fmt},${normal_fmt}}"
      else
        tmux set-window-option -g window-status-format "${normal_fmt}"
      fi
    fi
  else
    tmux set-window-option -g window-status-current-format "#[fg=${active_window_fg}]#[bg=${active_window_bg}] #I #W${current_flags} "
    normal_fmt="#[fg=${inactive_window_fg}]#[bg=${inactive_window_bg}] #I #W${flags}"
    if [ "$window_bell" = "true" ]; then
      bell_fmt="#[fg=${window_bell_fg}]#[bg=${window_bell_bg}]${blink_on} #I #W${bell_flags}${blink_off}"
      tmux set-window-option -g window-status-format "#{?window_bell_flag,${bell_fmt},${normal_fmt}}"
    else
      tmux set-window-option -g window-status-format "${normal_fmt}"
    fi
  fi
  tmux set-window-option -g window-status-activity-style "bold"
  if [ "$window_bell" = "true" ]; then
    tmux set-window-option -g window-status-bell-style "none"
  else
    tmux set-window-option -g window-status-bell-style "bold"
  fi
}

# run main function
main
