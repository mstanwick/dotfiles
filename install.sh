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

if [ -d "$PRIVATE" ] && [ -d "$WORK" ]; then
  die "both $PRIVATE and $WORK exist. A machine gets one or the other, never both."
fi

REPOS=("$PUBLIC")
[ -d "$PRIVATE" ] && REPOS+=("$PRIVATE")
[ -d "$WORK" ] && REPOS+=("$WORK")

for repo in "${REPOS[@]}"; do
  [ -f "$repo/.stowrc" ] || die "$repo has no .stowrc (it sets --target=~ --dotfiles --no-folding)."
done

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

# --- 5. zsh plugins ----------------------------------------------------------

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

# --- 6. Summary ------------------------------------------------------------

[ "$DRY" -eq 1 ] && exit 0
echo "Stowed: ${REPOS[*]}"
[ "$moved" -gt 0 ] && echo "Moved aside: $moved file(s), now ending in .pre-stow"
if [ ! -d "$PRIVATE" ] && [ ! -d "$WORK" ]; then
  echo "No private-dots or work-dots found next to $PUBLIC."
  echo "  Personal machine: clone private-dots there, then rerun this script."
  echo "  Work machine: create work-dots there (git init, no remote), then rerun."
fi
