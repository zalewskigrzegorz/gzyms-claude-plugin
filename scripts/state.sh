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
# PermissionRequest may still overwrite a "waits" the Notification wrote first: it knows what Claude asks.
event=$(field hook_event_name)
[ "$event" != PermissionRequest ] && grep -q "\"state\":\"$1\"" "$file" 2>/dev/null && exit 0

# What Claude waits for, in words. PermissionRequest knows the tool, a Notification only says "needs your permission".
message=$(field message)
if [ "$event" = PermissionRequest ]; then
  tool=$(field tool_name)
  case "$tool" in
    AskUserQuestion) message=$(field tool_input.questions.0.question) ;;
    Bash) message="Run: $(field tool_input.command)" ;;
    Write | Edit | MultiEdit | NotebookEdit) message="Edit $(field tool_input.file_path)" ;;
    WebFetch) message="Open $(field tool_input.url)" ;;
    *) message="Use $tool" ;;
  esac
fi

# The session's title says what it does: the one you gave it (Claude Desktop names every session), else Claude's own.
transcript=$(field transcript_path)
title=$(grep -o '"customTitle":"[^"]*"' "$transcript" 2>/dev/null | tail -1 | cut -d'"' -f4)
[ -n "$title" ] || title=$(grep -o '"aiTitle":"[^"]*"' "$transcript" 2>/dev/null | tail -1 | cut -d'"' -f4)

j() { local s="${1:0:300}"; s="${s//\\/\\\\}"; s="${s//\"/\\\"}"; printf '%s' "${s//[[:cntrl:]]/ }"; }
cwd=$(field cwd)
# No hook fires when Claude dies with its window, or when you reject a prompt or press Esc. Gzyms covers those
# itself: a session whose process is gone leaves the bar, and a transcript written after "waits" means it no longer waits.
p=$PPID pid=0
for _ in 1 2 3 4 5; do
  case "$(ps -o comm= -p "$p" 2>/dev/null)" in *claude*) pid=$p; break ;; esac
  p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
  [ -n "$p" ] && [ "$p" -gt 1 ] || break
done
mkdir -p "$dir" || exit 0
tmp="$file.$$"
printf '{"id":"%s","state":"%s","since":%s,"pid":%s,"transcript":"%s","cwd":"%s","name":"%s","title":"%s","message":"%s","tuios_pane":"%s","term":"%s","entry":"%s"}\n' \
  "$id" "$1" "$(date +%s)" "${pid:-0}" "$(j "$transcript")" "$(j "$cwd")" "$(j "${cwd##*/}")" "$(j "$title")" "$(j "$message")" \
  "$(j "${TUIOS_PANE_ID:-}")" "$(j "${TERM_PROGRAM:-}")" "$(j "${CLAUDE_CODE_ENTRYPOINT:-}")" > "$tmp" \
  && mv -f "$tmp" "$file"
rm -f "$tmp"
exit 0
