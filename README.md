# Tmac

A native macOS app that hosts a single isolated tmux instance — its own
socket, its own config, its own state — without touching your normal tmux
setup. State survives reboots via `tmux-resurrect` + `tmux-continuum`.

## Usage

- `bash setup.sh` — clone plugins, write `~/.config/tmac/{tmux.conf,config.json}`; optionally inherit your `~/.tmux.conf`.
- `make app` — release build, publish to `~/Applications/Tmac.app`.
- `make app-dev` — debug build (faster), publish to `~/Applications/Tmac.app`.

## Requirements

macOS 13+, `swift` ≥ 5.9, `tmux`, `git`.

## Troubleshooting

If Tmac is missing from Shortcuts' *Open App* picker after install:
`make restart-mac-pref-daemon`
