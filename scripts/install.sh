#!/usr/bin/env bash
set -euo pipefail
DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

chmod +x "$DIR/qsearch" "$DIR"/install-*.sh 2>/dev/null || true
printf 'Made scripts executable in: %s\n' "$DIR"

if [ "$(command -v qsearch || true)" = "$DIR/qsearch" ]; then
  printf 'qsearch is already on PATH.\n'
else
  printf 'Add this directory to PATH, e.g.:\n\n'
  printf '  export PATH="%s:$PATH"\n\n' "$DIR"
  printf 'See README.md for bash, zsh and fish instructions.\n'
fi
