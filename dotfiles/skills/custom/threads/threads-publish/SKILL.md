---
name: threads-publish
description: Publish Threads posts via browser automation. Saves to draft by default, never auto-publishes. Archives after publish. Triggers on "threads-publish", "발행", "포스트 업로드", "publish", "쓰레드 발행".
---

# Threads Publish

브라우저 자동화(claude-in-chrome)를 사용하여 threads.net에 포스트를 발행하는 스킬. 초안 저장이 기본이며, 사용자 확인 없이는 절대 자동 발행하지 않는다.

## CRITICAL RULE

**절대 자동 발행 금지.** 모든 발행은 반드시 사용자의 명시적 확인("yes") 후에만 수행한다. `draft` 명령이 기본이며, `post` 명령도 확인 단계를 거친다.

## Data Dependencies

이 스킬은 다음 데이터/스킬에 의존한다:

- `threads-account`: `~/.claude/skills/threads-account/accounts/{id}/profile.yaml` — 계정 프로필
- `threads-context`: `save-post` 명령 — 발행 후 아카이브
- `claude-in-chrome` MCP 도구: 브라우저 자동화

## Commands

### `threads-publish draft <account-id>` — 초안 저장

작성된 포스트를 threads.net에 초안으로 저장한다. 발행하지 않는다.

**Flow:**
1. `accounts/{id}/profile.yaml`에서 계정 정보 확인
2. 발행할 포스트 텍스트 확인 (사용자에게 텍스트 요청 또는 이전 threads-write 결과 사용)
3. `mcp__claude-in-chrome__navigate`로 threads.net 이동
4. 로그인 상태 확인 (`mcp__claude-in-chrome__get_page_text`로 페이지 내용 확인)
   - 로그인 안 됨 → "threads.net에 로그인되어 있지 않습니다. 브라우저에서 로그인 후 다시 시도해주세요." 출력 후 중단
5. 새 포스트 작성 화면으로 이동
6. `mcp__claude-in-chrome__form_input` 또는 `mcp__claude-in-chrome__computer`로 텍스트 입력
7. 초안 저장 (Threads가 초안을 지원하는 경우)
   - 초안 미지원 시: 텍스트 입력 상태에서 멈추고 사용자에게 안내
8. "초안이 저장되었습니다. 발행하려면 `threads-publish post {id}`를 실행하세요." 출력

---

### `threads-publish post <account-id>` — 발행 (확인 필수)

포스트를 실제로 발행한다. **반드시 사용자 확인을 거친다.**

**Flow:**
1. `accounts/{id}/profile.yaml`에서 계정 정보 확인
2. 발행할 포스트 텍스트 확인
3. 포스트 내용 미리보기 표시:
   ```
   ## 발행 미리보기
   계정: {name} ({id})

   ---
   {포스트 본문}
   ---

   이 포스트를 발행하시겠습니까? (yes/no)
   ```
4. **사용자가 "yes"로 응답한 경우에만 진행** (그 외 응답 → 발행 취소)
5. `mcp__claude-in-chrome__navigate`로 threads.net 이동
6. 로그인 상태 확인
7. 새 포스트 작성 → 텍스트 입력 → 발행 버튼 클릭
8. 발행 성공 확인 (`mcp__claude-in-chrome__get_page_text`로 확인)
9. 발행 성공 시:
   - "포스트가 발행되었습니다." 출력
   - `threads-context save-post {id}` 자동 호출 → 아카이브
10. 발행 실패 시:
    - "발행에 실패했습니다. 수동으로 발행해주세요." 에러 출력

**발행 거부 시:**
- "발행이 취소되었습니다. 초안은 유지됩니다." 출력
- 아카이브 미실행

---

## 브라우저 자동화 가이드

### 사용 MCP 도구

| 도구 | 용도 |
|------|------|
| `mcp__claude-in-chrome__navigate` | threads.net 페이지 이동 |
| `mcp__claude-in-chrome__get_page_text` | 페이지 텍스트 읽기 (로그인 확인, 발행 확인) |
| `mcp__claude-in-chrome__read_page` | 페이지 구조 읽기 (버튼/입력 필드 위치 파악) |
| `mcp__claude-in-chrome__form_input` | 텍스트 입력 |
| `mcp__claude-in-chrome__computer` | 클릭, 키보드 입력 등 범용 상호작용 |
| `mcp__claude-in-chrome__find` | 페이지 내 요소 검색 |

### threads.net 발행 플로우

1. `https://www.threads.net` 접속
2. 새 글 작성 버튼 또는 `https://www.threads.net/create` 등 직접 URL
3. 텍스트 입력 영역에 포스트 본문 입력
4. "게시" 또는 "Post" 버튼 클릭 (발행 시에만)

### 에러 핸들링

- **페이지 로딩 실패**: "threads.net에 접속할 수 없습니다. 네트워크를 확인해주세요."
- **로그인 필요**: "로그인이 필요합니다. 브라우저에서 threads.net에 로그인해주세요."
- **UI 변경**: "포스트 작성 화면을 찾을 수 없습니다. Threads UI가 변경되었을 수 있습니다. 수동으로 진행해주세요."
- **발행 실패**: "발행 버튼 클릭 후 성공 확인이 안 됩니다. 브라우저에서 직접 확인해주세요."

## 스케줄 발행

Threads 플랫폼이 예약 발행을 지원하는 경우:
- 발행 확인 시 "지금 발행" 또는 "예약 발행" 선택지 제공
- 예약 시 날짜/시간 입력 받아 플랫폼의 스케줄 기능 사용

## 아카이브 연동

발행 성공 후 자동으로 `threads-context save-post <account-id>` 호출:
- topic, angle, key_claims, hashtags, 본문 전달
- 실패 시 수동 실행 안내: "아카이브 저장에 실패했습니다. 수동으로 `threads-context save-post {id}`를 실행해주세요."

## 주의사항

- 텍스트가 비어 있으면 발행/초안 저장 불가
- 브라우저가 열려 있어야 함 (claude-in-chrome 연결 필요)
- threads.net UI 변경 시 자동화가 실패할 수 있음 — 에러 메시지와 함께 수동 대체 안내
- 초안 저장 기능은 Threads 플랫폼 지원 여부에 따라 다름
