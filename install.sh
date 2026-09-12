#!/usr/bin/env bash
# qsearch installer.
#
# Run once after cloning:
#
#   git clone https://github.com/florianbuetow/qsearch-bash.git ~/scripts/qsearch
#   ~/scripts/qsearch/install.sh
#
# It makes the command executable, installs the dependencies that are
# missing, adds the command directory to PATH, and verifies the result.
set -uo pipefail

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
BIN_DIR="$REPO_DIR/scripts"

FAILURES=0

step() { printf '\n==> %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
ok()   { printf '    ok      %s\n' "$*"; }
bad()  { printf '    MISSING %s\n' "$*" >&2; FAILURES=$((FAILURES + 1)); }
warn() { printf '    warning: %s\n' "$*" >&2; }
die()  { printf '\nerror: %s\n' "$*" >&2; exit 2; }

have() { command -v "$1" >/dev/null 2>&1; }

# PATH entry written to the shell config, with $HOME kept symbolic.
path_entry() {
  case "$BIN_DIR" in
    "$HOME"/*) printf '$HOME%s' "${BIN_DIR#"$HOME"}" ;;
    *) printf '%s' "$BIN_DIR" ;;
  esac
}

# --- 1. executables ------------------------------------------------------

step "Making qsearch executable"
chmod +x "$BIN_DIR/qsearch" || die "cannot chmod $BIN_DIR/qsearch"
chmod +x "$REPO_DIR"/install-*.sh 2>/dev/null || true
info "$BIN_DIR/qsearch"

# --- 2. dependencies -----------------------------------------------------

step "Installing dependencies"
case "$(uname -s)" in
  Darwin) "$REPO_DIR/install-macos-deps.sh" || warn "dependency installation reported errors" ;;
  Linux)  "$REPO_DIR/install-linux-deps.sh" || warn "dependency installation reported errors" ;;
  *) die "unsupported operating system: $(uname -s) (qsearch supports macOS and Linux)" ;;
esac

# --- 3. PATH -------------------------------------------------------------

step "Adding qsearch to PATH"

shell_name="$(basename -- "${SHELL:-}")"
entry="$(path_entry)"

case "$shell_name" in
  zsh)
    rc="$HOME/.zshrc"
    line="export PATH=\"$entry:\$PATH\""
    ;;
  bash)
    if [ "$(uname -s)" = "Darwin" ] && [ -f "$HOME/.bash_profile" ]; then
      rc="$HOME/.bash_profile"
    else
      rc="$HOME/.bashrc"
    fi
    line="export PATH=\"$entry:\$PATH\""
    ;;
  fish)
    rc="$HOME/.config/fish/config.fish"
    line="fish_add_path $entry"
    ;;
  *)
    rc=""
    ;;
esac

if [ -z "$rc" ]; then
  warn "unrecognized shell '${shell_name:-unknown}'; add this to your shell config yourself:"
  info "export PATH=\"$entry:\$PATH\""
elif [ -f "$rc" ] && grep -qF "$BIN_DIR" "$rc" 2>/dev/null; then
  info "already configured in $rc"
elif [ -f "$rc" ] && grep -qF "$entry" "$rc" 2>/dev/null; then
  info "already configured in $rc"
else
  mkdir -p "$(dirname -- "$rc")"
  printf '\n# qsearch\n%s\n' "$line" >> "$rc" || die "cannot write to $rc"
  info "added to $rc"
fi

# --- 4. verification -----------------------------------------------------

step "Verifying installation"

PATH="$BIN_DIR:$PATH"

have qsearch && ok "qsearch      $(command -v qsearch)" || bad "qsearch"
have rg      && ok "rg           $(command -v rg)"      || bad "rg (ripgrep) - required"
have rga     && ok "rga          $(command -v rga)"     || bad "rga (ripgrep-all) - required"

if have stemwords; then
  ok "stemwords    $(command -v stemwords)"
else
  bad "stemwords (Snowball) - required for the default --linguistics snowball"
fi

for opt in pandoc pdftotext clawgrep; do
  if ! have "$opt"; then
    warn "$opt is not installed; the stages that need it will be skipped"
  elif [ "$opt" = "clawgrep" ] && ! clawgrep --version >/dev/null 2>&1; then
    # Present but non-functional: usually a missing per-platform binary.
    warn "clawgrep is on PATH but does not run; semantic search will produce nothing"
    warn "  try: npm install -g @clawgrep/clawgrep-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)"
  else
    ok "$opt $(command -v "$opt")"
  fi
done

# --- 5. result -----------------------------------------------------------

if [ "$FAILURES" -gt 0 ]; then
  printf '\nInstallation incomplete: %d required component(s) missing (see above).\n' "$FAILURES" >&2
  exit 1
fi

printf '\nInstallation complete.\n'
printf 'Open a new shell (or run: source %s) and try:\n\n' "${rc:-your shell config}"
printf '  qsearch "how are autonomous agents evaluated?" ~/Documents\n\n'
