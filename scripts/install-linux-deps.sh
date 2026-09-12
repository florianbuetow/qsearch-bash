#!/usr/bin/env bash
set -euo pipefail
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y ripgrep pandoc poppler-utils libstemmer-tools
else
  echo "Install ripgrep, pandoc, poppler/pdftotext, and Snowball stemwords with your package manager." >&2
fi

if ! command -v rga >/dev/null 2>&1; then
  if command -v cargo >/dev/null 2>&1; then
    cargo install --locked ripgrep_all
  else
    echo "rga is missing. Install ripgrep-all from its release package, Homebrew/Linuxbrew, or cargo." >&2
  fi
fi

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
