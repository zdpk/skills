---
name: threads-context
description: Load, check, and update context for Threads post consistency. Prevents duplicate topics, stance contradictions, and maintains post archive. Triggers on "threads-context", "컨텍스트 로드", "일관성 체크", "context load", "context check".
---

# Threads Context Manager

글 작성 전 계정의 축적된 컨텍스트를 로드하고, 일관성을 검증하며, 발행 후 데이터를 업데이트하는 스킬.

## Data Dependencies

이 스킬은 `threads-account` 스킬이 관리하는 데이터 구조에 의존한다:

```
~/.claude/skills/threads-account/accounts/{id}/
├── profile.yaml          # 계정 프로필 (threads-account 관리)
├── posts/                # 발행된 글 아카이브
│   └── {YYYY-MM-DD}_{slug}.md
├── stances.yaml          # 주제별 입장 레지스트리
└── topics-history.yaml   # 다룬 주제 이력
```

## Commands

### `threads-context load <account-id>` — 컨텍스트 로딩

글 작성 전에 반드시 실행. 해당 계정의 작성 컨텍스트를 수집하여 출력한다.

**로드 항목:**
1. **프로필 요약** — profile.yaml에서 domain, tone, target_audience, content_pillars, avoid_topics
2. **최근 포스트 10개** — posts/ 디렉토리에서 최신 10개 파일의 frontmatter (topic, date, angle, key_claims)
3. **전체 stances** — stances.yaml 전체
4. **최근 30일 주제 이력** — topics-history.yaml에서 최근 30일 항목

**Flow:**
1. `~/.claude/skills/threads-account/accounts/{id}/` 경로 확인
2. profile.yaml 로드 → 핵심 필드 추출
3. posts/ 디렉토리에서 파일명 기준 최신 10개 선택 → frontmatter만 파싱
4. stances.yaml 전체 로드
5. topics-history.yaml 로드 → 최근 30일 필터
6. 구조화된 형태로 출력

**Output format:**
```
## 계정: {name} ({domain})
톤: {tone 요약}
타겟: {target_audience}

## 최근 포스트 (10개)
| 날짜 | 주제 | 각도 | 핵심 주장 |
|------|------|------|----------|
| ... | ... | ... | ... |

## 현재 입장 (Stances)
- {key}: {stance} (since {first_mentioned})
- ...

## 최근 30일 주제 이력
- {date}: {topic} ({angle})
- ...
```

**옵션: `--topic <keyword>`**
- 특정 주제와 관련된 컨텍스트만 필터링
- posts에서 해당 키워드 포함 항목만, stances에서 관련 항목만 출력
- 주제 연관성은 키워드 매칭 + Claude 판단

**빈 상태 처리:**
- posts가 없으면: "아직 작성된 포스트가 없습니다"
- stances가 없으면: "등록된 입장이 없습니다"
- topics-history가 없으면: "주제 이력이 없습니다"

---

### `threads-context check-topic <account-id> <topic>` — 주제 중복 감지

작성하려는 주제가 이미 다뤄졌는지 확인한다.

**Flow:**
1. topics-history.yaml 로드
2. 입력된 topic과 기존 이력의 topic을 비교 (키워드 매칭)
3. 유사한 주제가 있으면 경고 출력

**유사 주제 발견 시 출력:**
```
⚠ 유사 주제 발견:
- "AI 코딩 도구 비교" (2026-03-16, 생산성 관점)

→ 같은 주제라도 다른 각도로 접근할 수 있습니다:
  - 가격/비용 비교
  - 특정 언어(Python/JS) 특화 비교
  - 초보자 vs 시니어 관점

진행하시겠습니까?
```

**유사 주제 없을 때:** "이전에 다루지 않은 주제입니다. 진행하세요."

---

### `threads-context check-stance <account-id>` — 입장 모순 감지

작성된 초안의 핵심 주장이 기존 stances와 모순되지 않는지 확인한다.

**Flow:**
1. stances.yaml 전체 로드
2. 초안의 핵심 주장(key_claims)을 사용자에게 요약 요청 또는 초안에서 추출
3. 각 주장을 기존 stances와 비교 (Claude 판단)
4. 모순 가능성이 있으면 경고 출력

**모순 감지 시 출력:**
```
⚠ 입장 모순 가능성:
기존 stance: "react-vs-vue" → "React 선호, 생태계와 채용시장 기준" (2026-03-10)
초안 주장: "Vue가 2026년 기준 React를 넘어섰다"

→ 선택지:
1. 초안 수정 (기존 입장 유지)
2. 입장 발전으로 기록 (evolved_from 추가)
3. 무시하고 진행
```

**입장 발전(evolution) 처리:**
사용자가 "입장 발전"을 선택하면:
```yaml
# stances.yaml 업데이트
react-vs-vue:
  stance: "2026년 기준 Vue 3의 성장으로 상황 변화, 프로젝트 규모별 선택 권장"
  first_mentioned: 2026-03-10
  evolved_from:
    stance: "React 선호, 생태계와 채용시장 기준"
    date: 2026-03-10
  posts: ["2026-03-10_react-vs-vue.md", "2026-03-20_vue-comeback.md"]
```

---

### `threads-context save-post <account-id>` — 포스트 아카이브 저장

발행 확정된 포스트를 아카이브하고 관련 데이터를 업데이트한다.

**Flow:**
1. 사용자에게 포스트 정보 확인:
   - topic, angle, key_claims (배열), hashtags, 본문
2. 파일명 생성: `{YYYY-MM-DD}_{slug}.md`
   - slug는 topic에서 자동 생성 (한글은 영문 변환 또는 kebab-case)
3. frontmatter + 본문으로 마크다운 파일 생성
4. `posts/` 디렉토리에 저장
5. 자동으로 다음 업데이트 수행:

**포스트 파일 형식:**
```markdown
---
topic: "주제"
date: YYYY-MM-DD
angle: "접근 각도"
key_claims:
  - "핵심 주장 1"
  - "핵심 주장 2"
stances_referenced:
  - stance-key-1
stances_new:
  - key: "new-stance-key"
    stance: "새로운 입장 내용"
hashtags: ["#tag1", "#tag2"]
---

포스트 본문 전체
```

**자동 업데이트 (save-post 실행 시 함께 수행):**

1. **stances.yaml 업데이트:**
   - `stances_new`에 명시된 항목 → 새 stance 추가
   - `stances_referenced`에 명시된 항목 → 해당 stance의 posts 배열에 파일명 추가

2. **topics-history.yaml 추가:**
   ```yaml
   - topic: "주제"
     date: YYYY-MM-DD
     angle: "접근 각도"
     post: "YYYY-MM-DD_slug.md"
   ```

---

## 다른 스킬에서의 사용 패턴

### threads-write에서 호출
```
1. threads-context load {id}           ← 작성 전 컨텍스트 로드
2. threads-context check-topic {id} {topic}  ← 주제 중복 확인
3. [글 작성]
4. threads-context check-stance {id}    ← 초안 입장 모순 확인
5. [사용자 리뷰/수정]
```

### threads-publish에서 호출
```
1. [발행 처리]
2. threads-context save-post {id}       ← 아카이브 + 자동 업데이트
```

## 주의사항

- stances.yaml이 없으면 빈 파일로 초기화 (`{}`)
- topics-history.yaml이 없으면 빈 배열로 초기화 (`[]`)
- posts/ 디렉토리가 없으면 자동 생성
- 파일 읽기/쓰기 실패 시 에러 메시지와 함께 수동 처리 안내
