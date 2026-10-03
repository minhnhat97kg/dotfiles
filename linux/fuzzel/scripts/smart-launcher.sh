#!/usr/bin/env bash
# Smart fuzzel launcher: web search, direct URLs, quick calculator.
# Mod+D still does plain app launching; this is the "everything else" launcher.
set -euo pipefail

urlencode() { jq -rn --arg q "$1" '$q|@uri'; }

open_url() { xdg-open "$1" >/dev/null 2>&1 & disown; }

search() {
    local engine="$1" query="$2" enc
    enc="$(urlencode "$query")"
    case "$engine" in
        google)  open_url "https://www.google.com/search?q=${enc}" ;;
        ddg)     open_url "https://duckduckgo.com/?q=${enc}" ;;
        youtube) open_url "https://www.youtube.com/results?search_query=${enc}" ;;
        wiki)    open_url "https://en.wikipedia.org/wiki/Special:Search?search=${enc}" ;;
        github)  open_url "https://github.com/search?q=${enc}" ;;
        so)      open_url "https://stackoverflow.com/search?q=${enc}" ;;
    esac
}

engines="Google\nDuckDuckGo\nYouTube\nWikipedia\nGitHub\nStack Overflow"

input="$(printf '%b' "$engines" | fuzzel --dmenu --prompt 'Search/URL/calc: ' || true)"
[ -z "$input" ] && exit 0

# Picked a bare engine name from the list with no query typed -> ask for the query.
case "$input" in
    Google|DuckDuckGo|YouTube|Wikipedia|GitHub|"Stack Overflow")
        query="$(fuzzel --dmenu --prompt "${input}: " </dev/null || true)"
        [ -z "$query" ] && exit 0
        case "$input" in
            Google) search google "$query" ;;
            DuckDuckGo) search ddg "$query" ;;
            YouTube) search youtube "$query" ;;
            Wikipedia) search wiki "$query" ;;
            GitHub) search github "$query" ;;
            "Stack Overflow") search so "$query" ;;
        esac
        exit 0
        ;;
esac

# Bang-prefixed query, e.g. "yt lofi beats", "gh niri compositor"
read -r prefix rest <<<"$input"
case "$prefix" in
    g)    search google "$rest"; exit 0 ;;
    ddg)  search ddg "$rest"; exit 0 ;;
    yt)   search youtube "$rest"; exit 0 ;;
    wiki) search wiki "$rest"; exit 0 ;;
    gh)   search github "$rest"; exit 0 ;;
    so)   search so "$rest"; exit 0 ;;
esac

# Looks like a URL or bare domain -> open directly.
if [[ "$input" =~ ^[a-zA-Z]+://[^[:space:]]+$ ]] || [[ "$input" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(/[^[:space:]]*)?$ && ! "$input" =~ [[:space:]] ]]; then
    case "$input" in
        *://*) open_url "$input" ;;
        *) open_url "https://$input" ;;
    esac
    exit 0
fi

# Pure arithmetic -> calculator, result shown via notification.
if [[ "$input" =~ ^[0-9.\ ()+*/^%-]+$ ]] && [[ "$input" =~ [0-9] ]]; then
    result="$(echo "$input" | bc -l 2>/dev/null || true)"
    if [ -n "$result" ]; then
        notify-send "Calculator" "${input} = ${result}"
        exit 0
    fi
fi

# Fallback: treat the whole thing as a Google search.
search google "$input"
