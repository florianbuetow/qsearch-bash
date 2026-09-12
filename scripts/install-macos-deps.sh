#!/usr/bin/env bash
set -euo pipefail
command -v brew >/dev/null 2>&1 || { echo "Homebrew is required." >&2; exit 2; }
brew install ripgrep ripgrep-all snowball pandoc poppler
if ! command -v clawgrep >/dev/null 2>&1; then
  if command -v npm >/dev/null 2>&1; then
    npm install -g clawgrep
  elif command -v cargo >/dev/null 2>&1; then
    cargo install clawgrep
  elif command -v pipx >/dev/null 2>&1; then
    pipx install clawgrep
  else
    echo "Install clawgrep with npm, cargo, or pip/pipx." >&2
  fi
fi
