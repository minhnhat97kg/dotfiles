#!/usr/bin/env bash
# Status-bar segment:  <branch> [│ <files> +<ins> -<del>]
#
# The branch name and the working-tree diff come from this single script so the
# status bar needs only one `#(...)` substitution for both. That matters: tmux
# re-runs every `#()` whenever it redraws the status line (which happens on
# essentially every keystroke), so each extra command is another fork+exec per
# key press. Inside a repo with a clean tree the diff suffix collapses to
# nothing; outside a repo the branch is shown as an em dash.
#
# Usage: git-summary.sh <path> <c_green> <c_red> <c_dim> <c_sep>
# Colours are passed in as literal hex because tmux does not expand #{@c_*}
# inside the output of #(), only #[...] style directives.

set -uo pipefail

path=${1:-$PWD}
c_green=${2:-green}
c_red=${3:-red}
c_dim=${4:-default}
c_sep=${5:-default}

# Not a repo (or unreadable path): show a placeholder branch and stop.
if ! cd "$path" 2>/dev/null || ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf '#[fg=%s]— ' "$c_dim"
    exit 0
fi

# Branch name; fall back to the short SHA when HEAD is detached.
branch=$(git symbolic-ref --short -q HEAD 2>/dev/null) \
    || branch=$(git rev-parse --short HEAD 2>/dev/null) \
    || branch='—'

out="#[fg=${c_dim}]${branch}"

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

if (( files > 0 )); then
    out+=" #[fg=${c_sep}]│ #[fg=${c_dim}]${files} #[fg=${c_green}]+${ins} #[fg=${c_red}]-${del}"
fi

printf '%s ' "$out"
