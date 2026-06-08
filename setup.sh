#!/bin/bash
# Tmac setup.
#
# First run:
#   - clones tmux-resurrect / tmux-continuum into ~/.config/tmac/plugins/
#   - prompts whether to inherit your system tmux config
#   - writes ~/.config/tmac/{tmux.conf,config.json}
#
# Rerun:
#   - prompts: keep existing configs+state, or reset them
#   - on reset: wipes state/resurrect snapshots and regenerates configs
#
# Always:
#   - builds Tmac.app (release) and publishes to ~/Applications/
#
# Requires tmux on PATH (`brew install tmux`) and git.
set -euo pipefail

CONFIG_DIR="$HOME/.config/tmac"
PLUGINS_DIR="$CONFIG_DIR/plugins"
STATE_DIR="$CONFIG_DIR/state/resurrect"
TMUX_CONF="$CONFIG_DIR/tmux.conf"
TMAC_CONF="$CONFIG_DIR/config.json"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/setup"

green()  { printf "\033[32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[33m%s\033[0m\n" "$1"; }
red()    { printf "\033[31m%s\033[0m\n" "$1" >&2; }

# 1. tmux must be installed
if ! command -v tmux >/dev/null 2>&1; then
    red "tmux not found on PATH. Install it (e.g. 'brew install tmux') and re-run."
    exit 1
fi
green ">>> tmux: $(tmux -V)"

# 2. Plugins (clone if missing)
mkdir -p "$PLUGINS_DIR"
clone_plugin() {
    local name="$1"
    local dest="$PLUGINS_DIR/$name"
    if [[ -d "$dest/.git" ]]; then
        green ">>> $name already present"
    else
        yellow ">>> Cloning $name"
        rm -rf "$dest"
        git clone --depth 1 "https://github.com/tmux-plugins/$name" "$dest"
    fi
}
clone_plugin tmux-resurrect
clone_plugin tmux-continuum

# 3. First-time vs rerun
WRITE_CONFIGS="yes"
WIPE_STATE="no"
if [[ -f "$TMUX_CONF" || -f "$TMAC_CONF" ]]; then
    printf "Existing config detected. Reset configs and state? [y/N] "
    read -r ans || ans=""
    case "$ans" in
        [yY]|[yY][eE][sS]) WRITE_CONFIGS="yes"; WIPE_STATE="yes" ;;
        *)                 WRITE_CONFIGS="no";  WIPE_STATE="no"  ;;
    esac
fi

# 4. Wipe state on reset
if [[ "$WIPE_STATE" == "yes" ]]; then
    yellow ">>> Wiping $STATE_DIR (snapshots deleted)"
    rm -rf "$STATE_DIR"
fi
mkdir -p "$STATE_DIR"

# 5. Regenerate configs
if [[ "$WRITE_CONFIGS" == "yes" ]]; then
    USER_TMUX_CONF=""
    for cand in "$HOME/.config/tmux/tmux.conf" "$HOME/.tmux.conf"; do
        if [[ -f "$cand" ]]; then
            USER_TMUX_CONF="$cand"
            break
        fi
    done

    INHERIT="no"
    if [[ -n "$USER_TMUX_CONF" ]]; then
        printf "Inherit settings from %s? [Y/n] " "$USER_TMUX_CONF"
        read -r ans || ans=""
        case "$ans" in
            [nN]|[nN][oO]) INHERIT="no"  ;;
            *)             INHERIT="yes" ;;
        esac
    fi

    yellow ">>> Writing $TMUX_CONF"
    {
        if [[ "$INHERIT" == "yes" ]]; then
            sed -e "s|__USER_TMUX_CONF__|$USER_TMUX_CONF|g" \
                -e "s|__TMAC_TMUX_CONF__|$TMUX_CONF|g" \
                "$TEMPLATE_DIR/tmux.conf.inherit.template"
        fi
        sed -e "s|__TMAC_STATE_DIR__|$STATE_DIR|g" \
            -e "s|__TMAC_PLUGINS_DIR__|$PLUGINS_DIR|g" \
            "$TEMPLATE_DIR/tmux.conf.template"
    } > "$TMUX_CONF"
    if [[ "$INHERIT" == "yes" ]]; then
        green "    inheriting from: $USER_TMUX_CONF"
    else
        green "    fully isolated (no inheritance)"
    fi

    yellow ">>> Writing $TMAC_CONF"
    sed -e "s|__TMAC_TMUX_CONF__|$TMUX_CONF|g" \\
        "$TEMPLATE_DIR/config.json.template" > "$TMAC_CONF"

    yellow ">>> Writing $CONFIG_DIR/zsh/.zshrc"
    mkdir -p "$CONFIG_DIR/zsh"
    cp "$TEMPLATE_DIR/zshrc.template" "$CONFIG_DIR/zsh/.zshrc"
else
    green ">>> Keeping existing $TMUX_CONF and $TMAC_CONF"
fi

# 6. Build + publish
yellow ">>> Building & publishing Tmac.app"
( cd "$SCRIPT_DIR" && make -s app )

echo
green "Setup complete."
echo
echo -e "If Tmac is not available for selection in Shortcuts.app, run: \033[38;5;93mmake restart-mac-pref-daemon\033[0m"
