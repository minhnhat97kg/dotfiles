#!/usr/bin/env bash
# Working-tree change summary for the tmux status bar:  <files> +<ins> -<del>
# Prints nothing at all when the tree is clean or the path isn't a git repo, so
# the segment (and its leading separator) disappears instead of showing zeros.
#
# Usage: git-summary.sh <path> <c_green> <c_red> <c_dim> <c_gray3>
# Colours are passed in as literal hex because tmux does not expand #{@c_*}
# inside the output of #(), only #[...] style directives.

set -uo pipefail

path=${1:-$PWD}
c_green=${2:-green}
c_red=${3:-red}
c_dim=${4:-default}
c_sep=${5:-default}

cd "$path" 2>/dev/null || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# Before the first commit there is no HEAD to diff against; the empty-tree
# object stands in for it so a fresh repo still reports its staged content.
base=HEAD
git rev-parse --verify --quiet HEAD >/dev/null 2>&1 \
  || base=4b825dc642cb6eb9a060e54bf8d69288fbee4904

# Staged + unstaged against HEAD in one pass. Binary files report "-" in the
# numstat columns; they count as changed files but contribute no line counts.
read -r files ins del < <(
  git diff --numstat "$base" 2>/dev/null | awk '
    { n++ }
    $1 ~ /^[0-9]+$/ { a += $1 }
    $2 ~ /^[0-9]+$/ { d += $2 }
    END { printf "%d %d %d\n", n, a, d }
  '
)

# Untracked files add to the file count only — their lines are deliberately not
# counted, to keep this to a fixed two git calls per status refresh.
untracked=$(git ls-files --others --exclude-standard | wc -l)
files=$(( files + untracked ))

(( files == 0 )) && exit 0

printf '#[fg=%s]│ #[fg=%s] %d #[fg=%s]+%d #[fg=%s]-%d ' \
  "$c_sep" "$c_dim" "$files" "$c_green" "$ins" "$c_red" "$del"
