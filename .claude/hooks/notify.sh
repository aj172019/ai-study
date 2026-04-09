#!/usr/bin/env bash
# Claude Code Notification Hook
# Disable with CLAUDE_NOTIFY=0

set -euo pipefail

[[ "${CLAUDE_NOTIFY:-1}" == "0" ]] && exit 0

INPUT="$(cat)"

if ! command -v jq &>/dev/null; then
    osascript -e 'display notification "입력을 기다리고 있습니다" with title "Claude Code" sound name "Glass"'
    exit 0
fi

MESSAGE=$(echo "$INPUT" | jq -r '.message // "입력을 기다리고 있습니다"')
NTYPE=$(echo "$INPUT" | jq -r '.notification_type // ""')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# Sound
case "$NTYPE" in
    permission_prompt) SOUND="Sosumi" ;;
    *)                 SOUND="Glass" ;;
esac

# Title: first user message from transcript
TITLE=""
if [[ -n "$TRANSCRIPT" && -f "$TRANSCRIPT" ]]; then
    TITLE=$(grep -m1 '"type":"human"' "$TRANSCRIPT" 2>/dev/null \
        | jq -r '.message.content | if type == "array" then map(select(.type == "text") | .text) | join(" ") elif type == "string" then . else "" end' 2>/dev/null \
        | head -c 60 | tr '\n' ' ' || true)
fi
[[ -z "$TITLE" && -n "$CWD" ]] && TITLE=$(basename "$CWD")
[[ -z "$TITLE" ]] && TITLE="Claude Code"

osascript -e "display notification \"$MESSAGE\" with title \"$TITLE\" sound name \"$SOUND\"" 2>/dev/null || true
