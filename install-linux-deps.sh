#!/usr/bin/env bash
# Install qsearch's dependencies on Debian/Ubuntu-like Linux.
#
# Only missing tools are installed, so existing packages are left alone.
set -uo pipefail

info() { printf '    %s\n' "$*"; }
warn() { printf '    warning: %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

# command -> apt package
missing_pkgs=()
have rg        || missing_pkgs+=(ripgrep)
have pandoc    || missing_pkgs+=(pandoc)
have pdftotext || missing_pkgs+=(poppler-utils)
have stemwords || missing_pkgs+=(libstemmer-tools)

if [ "${#missing_pkgs[@]}" -eq 0 ]; then
  info "all apt-provided dependencies already installed"
elif have apt-get; then
  info "installing: ${missing_pkgs[*]}"
  sudo apt-get update
  sudo apt-get install -y "${missing_pkgs[@]}" || warn "apt-get install failed"
else
  warn "no apt-get; install these with your package manager: ${missing_pkgs[*]}"
  warn "(ripgrep, pandoc, poppler/pdftotext, and Snowball stemwords)"
fi

if have rga; then
  info "rga already installed, skipping"
elif have cargo; then
  info "installing ripgrep_all with cargo"
  cargo install --locked ripgrep_all || warn "cargo install ripgrep_all failed"
else
  warn "rga is missing. Install ripgrep-all from its release package, Linuxbrew, or cargo."
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
