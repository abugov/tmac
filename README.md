# Tmac

A native macOS app that hosts a single isolated tmux instance — its own
socket, its own config, its own state — without touching your normal tmux
setup. State survives reboots via `tmux-resurrect` + `tmux-continuum`.

## Installation

Clone and run `bash setup.sh` for first time install/reconfigure.

## Usage

- `make app` — release build, publish to `~/Applications/Tmac.app`.
- `make app-dev` — debug build (faster), publish to `~/Applications/Tmac.app`.
