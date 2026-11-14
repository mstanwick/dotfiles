#!/usr/bin/env bash
# Set up these dotfiles on this machine with GNU Stow.
#
#   ./install.sh            set up (safe to rerun)
#   ./install.sh --dry-run  show what would happen, change nothing
#
# Stows every package (top-level folder) in this repo, plus the one
# optional layer found next to it:
#   ../private-dots  personal machines
#   ../work-dots     work machines
# A machine has one or the other, never both; the script stops if it
# finds both. Files already in the way are renamed to NAME.pre-stow,
# never deleted.
#
# Written for bash 3.2 and BSD tools so it also runs on macOS.
set -euo pipefail

DRY=0
case "${1:-}" in
  --dry-run) DRY=1 ;;
  "") ;;
  *) echo "usage: $0 [--dry-run]" >&2; exit 2 ;;
esac

run() { if [ "$DRY" -eq 1 ]; then echo "would: $*"; else "$@"; fi; }
die() { printf 'STOP: %s\n' "$*" >&2; exit 1; }

PUBLIC=$(cd "$(dirname "$0")" && pwd -P)
PARENT=$(dirname "$PUBLIC")
PRIVATE="$PARENT/private-dots"
WORK="$PARENT/work-dots"

ZSH_PLUGINS="powerlevel10k https://github.com/romkatv/powerlevel10k.git
zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git
zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git"

# Files that would stop Emacs from reading ~/.emacs.d/init.el.
EMACS_SHADOWS=".emacs .emacs.el"

# --- 1. Checks before changing anything --------------------------------

for cmd in git stow; do
  command -v "$cmd" >/dev/null 2>&1 ||
    die "$cmd is not installed. Fedora: sudo dnf install $cmd | macOS: brew install $cmd | Debian/Ubuntu: sudo apt install $cmd"
done

# Preflight: collect every problem so one --dry-run shows the full list.
# STOP = would silently do the wrong thing; WARN = shows up as a visible error.
STOPS=""
WARNS=""
stop() { STOPS="$STOPS  - $*
"; }
warn() { WARNS="$WARNS  - $*
"; }

if [ -d "$PRIVATE" ] && [ -d "$WORK" ]; then
  stop "Both $PRIVATE and $WORK exist. A machine gets one or the other, never both."
fi

REPOS=("$PUBLIC")
[ -d "$PRIVATE" ] && REPOS+=("$PRIVATE")
[ -d "$WORK" ] && REPOS+=("$WORK")

for repo in "${REPOS[@]}"; do
  [ -f "$repo/.stowrc" ] || stop "$repo has no .stowrc (it sets --target=~ --dotfiles --no-folding)."
done

# The personal layer is a clone of GitHub; a local-only repo in its place is
# almost certainly work settings under the old name.
if [ -d "$PRIVATE" ] && [ -z "$(git -C "$PRIVATE" remote 2>/dev/null)" ]; then
  stop "$PRIVATE has no remote, so it isn't a clone of your private GitHub repo. If it holds work settings, rename it to work-dots and use work.* file names."
fi
# Work settings must never point at GitHub.
if [ -d "$WORK" ] && git -C "$WORK" remote -v 2>/dev/null | grep -q 'github\.com'; then
  stop "$WORK has a GitHub remote. Remove it: git -C $WORK remote remove <name>"
fi

# ~/.gitconfig is read after ~/.config/git/config, so its values win.
# An email there would replace the one from private.gitconfig or work.gitconfig.
if [ -f "$HOME/.gitconfig" ]; then
  home_email=$(git config -f "$HOME/.gitconfig" --get user.email 2>/dev/null || true)
  layer_email=""
  for f in "$PRIVATE/git/dot-config/git/private.gitconfig" "$WORK/git/dot-config/git/work.gitconfig"; do
    [ -f "$f" ] && layer_email=$(git config -f "$f" --get user.email 2>/dev/null || true)
  done
  if [ -n "$home_email" ] && [ "$home_email" != "$layer_email" ]; then
    stop "$HOME/.gitconfig sets user.email = $home_email, which would override ${layer_email:-the email from your private or work layer}. Remove the [user] email line from $HOME/.gitconfig."
  elif [ -n "$home_email" ]; then
    warn "$HOME/.gitconfig repeats user.email; you can remove that line."
  fi
  if git config -f "$HOME/.gitconfig" --get-all credential.helper >/dev/null 2>&1; then
    warn "$HOME/.gitconfig sets credential.helper; it adds to the gh helper from the shared config. Remove it unless you need it."
  fi
fi

# The Emacs config uses use-package's :vc keyword, new in Emacs 30.
if command -v emacs >/dev/null 2>&1; then
  emacs_major=$(emacs --version 2>/dev/null | sed -nE '1s/^GNU Emacs ([0-9]+).*/\1/p')
  if [ -n "$emacs_major" ] && [ "$emacs_major" -lt 30 ]; then
    warn "Emacs $emacs_major is too old; the config needs Emacs 30 or newer."
  fi
else
  warn "emacs isn't on PATH, so its version couldn't be checked (the config needs Emacs 30 or newer)."
fi

# An old copy of use-package from MELPA hides the built-in one, which has :vc.
for d in "$HOME"/.emacs.d/elpa/use-package-[0-9]* "$HOME"/.emacs.d/elpa/bind-key-[0-9]*; do
  [ -d "$d" ] || continue
  warn "$d is an old MELPA copy that hides Emacs's built-in version (Emacs would fail with 'Unrecognized keyword: :vc'). Move it out of elpa/ and remove it from package-selected-packages in ~/.emacs.d/emacs-custom.el."
done

command -v gh >/dev/null 2>&1 ||
  warn "gh isn't installed; git gets GitHub credentials from it. Install it and run: gh auth login"

if [ -n "$WARNS" ]; then printf 'WARNING:\n%s' "$WARNS" >&2; fi
if [ -n "$STOPS" ]; then
  printf 'STOP: fix these first, then rerun (nothing was changed):\n%s' "$STOPS" >&2
  exit 1
fi

# Top-level folders of a repo are its Stow packages.
packages() {
  local d
  for d in "$1"/*/; do
    [ -d "$d" ] && basename "$d"
  done
  return 0
}

# Where a package file lands in ~: drop the package folder, then turn each
# leading "dot-" into "." the way stow --dotfiles does.
target_of() {
  printf '%s\n' "${1#*/}" | sed -E 's#(^|/)dot-#\1.#g'
}

# --- 2. Find files in the way ------------------------------------------
# A target is fine if it is missing or already resolves to the repo file.
# Anything else (a real file, or a link to somewhere else) gets moved aside.

MOVES=""
plan_move() { # $1 = path relative to ~
  local t="$HOME/$1"
  if [ -d "$t" ] && [ ! -L "$t" ]; then
    die "$t is a folder, but a file belongs there. Move it by hand, then rerun."
  fi
  if [ -e "$t.pre-stow" ] || [ -L "$t.pre-stow" ]; then
    die "$t is in the way and $t.pre-stow already exists. Sort them out by hand, then rerun."
  fi
  MOVES="$MOVES$1
"
}

for repo in "${REPOS[@]}"; do
  pkgs=$(packages "$repo")
  [ -n "$pkgs" ] || continue
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    target=$(target_of "$rel")
    t="$HOME/$target"
    if [ -e "$t" ] || [ -L "$t" ]; then
      # -ef: same file after following links, i.e. already linked to the repo.
      [ "$t" -ef "$repo/$rel" ] && continue
      plan_move "$target"
    fi
  done <<EOF
$(cd "$repo" && for p in $pkgs; do find "$p" \( -type f -o -type l \); done)
EOF
done

if [ -d "$PUBLIC/emacs" ]; then
  for f in $EMACS_SHADOWS; do
    if [ -e "$HOME/$f" ] || [ -L "$HOME/$f" ]; then plan_move "$f"; fi
  done
fi

# --- 3. Move them aside -------------------------------------------------

moved=0
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  run mv -- "$HOME/$rel" "$HOME/$rel.pre-stow"
  moved=$((moved + 1))
done <<EOF
$MOVES
EOF

# --- 4. Stow --------------------------------------------------------------
# Run from inside each repo so its .stowrc applies. Stow's own dry run
# goes first, so a conflict this script missed stops before any linking.

for repo in "${REPOS[@]}"; do
  pkgs=$(packages "$repo")
  [ -n "$pkgs" ] || continue
  if [ "$DRY" -eq 1 ]; then
    echo "would: stow $(printf '%s' "$pkgs" | tr '\n' ' ') (in $repo)"
    continue
  fi
  # shellcheck disable=SC2086  # $pkgs is a list of folder names
  if ! (cd "$repo" && stow -n $pkgs); then
    die "stow found a conflict in $repo (see above). Files moved so far end in .pre-stow."
  fi
  # shellcheck disable=SC2086
  (cd "$repo" && stow $pkgs)
done

# --- 5. Machine-only git config ---------------------------------------------
# Without ~/.gitconfig, `git config --global` writes to ~/.config/git/config,
# which is a link into this public repo. An empty ~/.gitconfig catches those
# writes instead; git reads it last, so it also works as a machine-only layer.

if [ ! -e "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
  if [ "$DRY" -eq 1 ]; then
    echo "would: create ~/.gitconfig (empty, for this machine's own settings)"
  else
    printf '%s\n' \
      "# This machine's own git settings. Not in any repo." \
      "# Shared settings: ~/.config/git/config (dotfiles) plus private.gitconfig" \
      "# or work.gitconfig. Settings here win over those. Don't set user.email here." \
      > "$HOME/.gitconfig"
  fi
fi

# --- 6. zsh plugins ----------------------------------------------------------

if [ -d "$PUBLIC/zsh" ]; then
  while read -r name url; do
    [ -n "$name" ] || continue
    if [ ! -d "$HOME/.zsh/$name" ]; then
      run mkdir -p "$HOME/.zsh"
      run git clone --quiet --depth 1 "$url" "$HOME/.zsh/$name"
    fi
  done <<EOF
$ZSH_PLUGINS
EOF
fi

# --- 7. Summary ------------------------------------------------------------

[ "$DRY" -eq 1 ] && exit 0
echo "Stowed: ${REPOS[*]}"
[ "$moved" -gt 0 ] && echo "Moved aside: $moved file(s), now ending in .pre-stow"
if [ ! -d "$PRIVATE" ] && [ ! -d "$WORK" ]; then
  echo "No private-dots or work-dots found next to $PUBLIC."
  echo "  Personal machine: clone private-dots there, then rerun this script."
  echo "  Work machine: create work-dots there (git init, no remote), then rerun."
fi
