---
name: re
description: Restart current session to reload skills and hooks
disable-model-invocation: true
allowed-tools: Bash
---

# Session Restart

현재 세션을 종료하고 같은 세션으로 재접속합니다.

## Instructions

1. 먼저 세션 ID를 저장합니다:
```bash
echo "${CLAUDE_SESSION_ID}" > ~/.claude/tmp/last_session_id
```

2. 사용자에게 다음을 안내합니다:
- "세션을 재시작합니다. 터미널에서 `re`를 입력하세요."

3. `/exit` 명령으로 세션을 종료합니다.
