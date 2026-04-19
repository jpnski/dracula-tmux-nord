# Dracula Tmux Nord

Stripped down version of Dracula Tmux, recolored with Nord palette

### Appearance:

![screenshot](screenshot.png)

### Changes:
* Removed many plugins and their configuration code
* Supports overriding more powerline visual elements in `tmux.conf`
  * Defines Nord theme palettes in config file, and applies the overrides
  * Falls back to default Dracula colors if no overrides applied
* Made for cohesion with `nord_minimal` Vim Airline and `nordic_nvim` Neovim theme

---

### Available Powerline Plugins

| Plugin | Description |
|--------|-------------|
| `git` | Git status |
| `cpu-usage` | CPU usage |
| `ram-usage` | RAM usage |
| `gpu-usage` | GPU usage |
| `gpu-ram-usage` | GPU RAM |
| `krbtgt` | Kerberos ticket |
| `kubernetes-context` | Kubernetes context |
| `terraform` | Terraform workspace |
| `continuum` | Continuum backup |
| `attached-clients` | Connected clients |
| `ssh-session` | SSH session |
| `uptime` | System uptime |
| `synchronize-panes` | Sync panes |
| `custom:<script>` | Run custom script |

### Added Overrides

| Option | Default | Description |
|--------|---------|-------------|
| `@dracula-left-icon-bg` | green | Left icon background |
| `@dracula-left-icon-fg` | dark_gray | Left icon foreground |
| `@dracula-left-icon-prefix-bg` | yellow | Prefix indicator background |
| `@dracula-left-icon-prefix-fg` | dark_gray | Prefix indicator foreground |
| `@dracula-active-window-bg` | dark_purple | Active window background |
| `@dracula-active-window-fg` | white | Active window foreground |
| `@dracula-inactive-window-bg` | (inherits) | Inactive window background |
| `@dracula-inactive-window-fg` | white | Inactive window foreground |
| `@dracula-flags-active-fg` | light_purple | Window flags (active) foreground |
| `@dracula-flags-inactive-fg` | dark_purple | Window flags (inactive) foreground |
| `@dracula-powerline-bg` | gray | Powerline background |


### Nord Color Theme
```bash
# ~/.config/tmux/tmux.conf

# Define Nord Colors
set -g @dracula-colors "
nord_dark1='#4C566A'    aurora_red='#BF616A'
nord_dark2='#434C5E'    aurora_orange='#D08770'
nord_dark3='#3B4252'    aurora_yellow='#EBCB8B'
nord_dark4='#2E3440'    aurora_green='#A3BE8C'
nord_dark5='#242933'    aurora_purple='#B48EAD'

nord_frost1='#8FBCBB'   nord_snow1='#ECEFF4'
nord_frost2='#88C0D0'   nord_snow2='#E5E9F0'
nord_frost3='#81A1C1'   nord_snow3='#D8DEE9'
nord_frost4='#5E81AC'
"

# Nord Re-coloring
set -g @dracula-powerline-bg        "nord_dark4"

set -g @dracula-left-icon-bg        "nord_dark3"
set -g @dracula-left-icon-fg        "nord_frost3"

set -g @dracula-left-icon-prefix-bg "aurora_orange"
set -g @dracula-left-icon-prefix-fg "nord_dark4"

set -g @dracula-active-window-bg    "aurora_purple"
set -g @dracula-active-window-fg    "nord_dark4"

set -g @dracula-inactive-window-bg  "nord_dark1"
set -g @dracula-inactive-window-fg  "nord_frost3"

set -g @dracula-flags-active-fg     "nord_snow1"
set -g @dracula-flags-inactive-fg   "nord_dark4"

set -g @dracula-git-colors          "nord_dark1 nord_frost3"
set -g @dracula-cpu-usage-colors    "nord_dark2 nord_frost3"
set -g @dracula-ram-usage-colors    "nord_dark3 nord_frost3"
```

## License

[MIT License](./LICENSE)
