#!/bin/bash
# Writes what a Claude Code session is doing to a file Gzyms reads: one JSON file per session.
# Usage (from hooks/hooks.json): state.sh idle|working|waits|done|end, the hook's JSON on stdin.
# A hook must never get in Claude's way, so every failure here ends quietly with exit 0.
dir="$HOME/Library/Application Support/Gzyms/agents/claude"
in=$(cat)
field() { plutil -extract "$1" raw -o - - <<< "$in" 2>/dev/null; }

# A subagent's hooks carry agent_id. Its parent session is the agent on the bar.
[ -n "$(field agent_id)" ] && exit 0
id=$(field session_id)
case "$id" in "" | */* | .*) exit 0 ;; esac
file="$dir/$id.json"

if [ "$1" = end ]; then rm -f "$file"; exit 0; fi

# PreToolUse fires on every tool call: write only when the state changes, so "since" keeps when the run began.
grep -q "\"state\":\"$1\"" "$file" 2>/dev/null && exit 0

j() { local s="${1:0:300}"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; printf '%s' "${s//[[:cntrl:]]/ }"; }
cwd=$(field cwd)
mkdir -p "$dir" || exit 0
tmp="$file.$$"
printf '{"id":"%s","state":"%s","since":%s,"cwd":"%s","name":"%s","message":"%s","tuios_pane":"%s","term":"%s","entry":"%s"}\n' \
  "$id" "$1" "$(date +%s)" "$(j "$cwd")" "$(j "${cwd##*/}")" "$(j "$(field message)")" \
  "$(j "${TUIOS_PANE_ID:-}")" "$(j "${TERM_PROGRAM:-}")" "$(j "${CLAUDE_CODE_ENTRYPOINT:-}")" > "$tmp" \
  && mv -f "$tmp" "$file"
rm -f "$tmp"
exit 0
