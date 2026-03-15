#!/bin/bash
# Claude Code 작업 완료 알림

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
CWD=$(echo "$INPUT" | jq -r '.cwd // "unknown"')

# 디바운스: 글로벌 5초 (서브프로세스 폭탄 방지) + 세션별 30초
NOW=$(date +%s)

GLOBAL_NOTIFY_FILE=~/.claude/tmp/last_notify_global
if [[ -f "$GLOBAL_NOTIFY_FILE" ]]; then
    LAST_GLOBAL=$(cat "$GLOBAL_NOTIFY_FILE")
    if [[ $((NOW - LAST_GLOBAL)) -lt 5 ]]; then
        exit 0
    fi
fi

LAST_NOTIFY_FILE=~/.claude/tmp/last_notify_${SESSION_ID}
if [[ -f "$LAST_NOTIFY_FILE" ]]; then
    LAST_NOTIFY=$(cat "$LAST_NOTIFY_FILE")
    if [[ $((NOW - LAST_NOTIFY)) -lt 30 ]]; then
        exit 0
    fi
fi

echo "$NOW" > "$GLOBAL_NOTIFY_FILE"
echo "$NOW" > "$LAST_NOTIFY_FILE"
SUMMARY=$(echo "$INPUT" | jq -r '.transcript_summary // "작업 완료"')

# 프로젝트 이름 추출
PROJECT_NAME=$(basename "$CWD")

# 완료 시간
COMPLETE_TIME=$(date "+%H:%M:%S")

# 소요 시간 계산
START_FILE=~/.claude/tmp/session_start_${SESSION_ID}
if [[ -f "$START_FILE" ]]; then
    START_TIME=$(cat "$START_FILE")
    NOW=$(date +%s)
    ELAPSED=$((NOW - START_TIME))

    # 시:분:초 형식으로 변환
    HOURS=$((ELAPSED / 3600))
    MINUTES=$(((ELAPSED % 3600) / 60))
    SECONDS=$((ELAPSED % 60))

    if [[ $HOURS -gt 0 ]]; then
        DURATION="${HOURS}h ${MINUTES}m ${SECONDS}s"
    elif [[ $MINUTES -gt 0 ]]; then
        DURATION="${MINUTES}m ${SECONDS}s"
    else
        DURATION="${SECONDS}s"
    fi
else
    DURATION="알 수 없음"
fi

# 요약 메시지 (너무 길면 자르기)
if [[ ${#SUMMARY} -gt 100 ]]; then
    SUMMARY="${SUMMARY:0:97}..."
fi

# Claude 앱 아이콘
ICON="/Applications/Claude.app/Contents/Resources/AppIcon.icns"

# 알림 보내기
terminal-notifier \
    -title "Claude Code ✓" \
    -subtitle "📁 ${PROJECT_NAME} | ⏱️ ${DURATION} | 🕐 ${COMPLETE_TIME}" \
    -message "${SUMMARY}" \
    -appIcon "$ICON" \
    -sound "Glass" \
    -group "claude-code"
