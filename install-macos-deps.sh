#!/usr/bin/env bash
# Install qsearch's dependencies on macOS.
#
# Only missing tools are installed. Packages you already have are left
# untouched, so this never upgrades an existing pandoc, poppler, or their
# dependencies behind your back.
set -uo pipefail

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
BIN_DIR="$REPO_DIR/scripts"

info() { printf '    %s\n' "$*"; }
warn() { printf '    warning: %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

have brew || { echo "    error: Homebrew is required (https://brew.sh)" >&2; exit 2; }

# command -> formula
install_if_missing() {
  local cmd="$1" formula="$2"
  if have "$cmd"; then
    info "$cmd already installed, skipping"
  else
    info "installing $formula (provides $cmd)"
    brew install "$formula" || warn "brew install $formula failed"
  fi
}

install_if_missing rg ripgrep
install_if_missing rga ripgrep-all
install_if_missing pandoc pandoc
install_if_missing pdftotext poppler

# Snowball: Homebrew's formula ships libstemmer and the stemwords example
# source, but no stemwords binary. Build it into the command directory so
# it lands on PATH with qsearch itself.
if have stemwords; then
  info "stemwords already installed, skipping"
else
  have brew && brew list snowball >/dev/null 2>&1 || {
    info "installing snowball (provides libstemmer)"
    brew install snowball || warn "brew install snowball failed"
  }

  sb_prefix="$(brew --prefix snowball 2>/dev/null || true)"
  if [ -z "$sb_prefix" ] || [ ! -d "$sb_prefix" ]; then
    warn "snowball is not installed; cannot build stemwords"
  elif ! have cc; then
    warn "no C compiler found; run 'xcode-select --install' then re-run this script"
  else
    examples="$sb_prefix/share/snowball/examples"
    src=""
    [ -f "$examples/stemwords.o" ] && src="$examples/stemwords.o"
    [ -z "$src" ] && [ -f "$examples/stemwords.c" ] && src="$examples/stemwords.c"

    if [ -z "$src" ]; then
      warn "stemwords source not found under $examples"
    else
      info "building stemwords from $src"
      if cc "$src" -I"$sb_prefix/include" -L"$sb_prefix/lib" -lstemmer \
           -o "$BIN_DIR/stemwords" 2>"$BIN_DIR/.stemwords-build.log"; then
        chmod +x "$BIN_DIR/stemwords"
        rm -f "$BIN_DIR/.stemwords-build.log"
        info "built $BIN_DIR/stemwords"
      else
        warn "building stemwords failed; see $BIN_DIR/.stemwords-build.log"
        warn "qsearch will run without stemming until this is resolved"
      fi
    fi
  fi
fi

if have clawgrep; then
  info "clawgrep already installed, skipping"
elif have npm; then
  info "installing clawgrep with npm"
  npm install -g clawgrep || warn "npm install -g clawgrep failed"
elif have cargo; then
  info "installing clawgrep with cargo"
  cargo install clawgrep || warn "cargo install clawgrep failed"
elif have pipx; then
  info "installing clawgrep with pipx"
  pipx install clawgrep || warn "pipx install clawgrep failed"
else
  warn "clawgrep is missing; install it with npm, cargo, or pipx for semantic search"
fi

# The clawgrep npm package is only a launcher - the real binary ships in a
# per-platform package. Without it the command exists and exits cleanly while
# producing nothing, so check that it actually runs.
if have clawgrep && ! clawgrep --version >/dev/null 2>&1; then
  case "$(uname -m)" in
    arm64) plat="darwin-arm64" ;;
    x86_64) plat="darwin-x64" ;;
    *) plat="" ;;
  esac
  if [ -n "$plat" ] && have npm; then
    info "installing clawgrep platform binary (@clawgrep/clawgrep-$plat)"
    npm install -g "@clawgrep/clawgrep-$plat" || warn "could not install @clawgrep/clawgrep-$plat"
  else
    warn "clawgrep is installed but its platform binary for $(uname -m) is missing"
  fi
fi
