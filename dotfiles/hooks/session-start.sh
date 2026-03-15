#!/bin/bash
# 세션 시작 시간 저장

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')

# 시작 시간 저장 (Unix timestamp)
mkdir -p ~/.claude/tmp
echo "$(date +%s)" > ~/.claude/tmp/session_start_${SESSION_ID}

# 24시간 이상 된 tmp 파일 정리
find ~/.claude/tmp -name "session_start_*" -mtime +0 -delete 2>/dev/null
find ~/.claude/tmp -name "last_notify_*" -not -name "last_notify_global" -mtime +0 -delete 2>/dev/null
