---
name: threads-account
description: Manage Threads account profiles/personas for the threads post automation pipeline. Create, list, show, and update account profiles stored as YAML. Triggers on "threads-account", "계정 관리", "계정 생성", "threads account", "쓰레드 계정".
---

# Threads Account Manager

Threads 포스트 자동 작성 파이프라인의 기반 스킬. 계정/페르소나별 주제, 톤, 전략을 YAML 프로필로 관리한다.

## Data Location

```
~/.claude/skills/threads-account/accounts/{id}/
├── profile.yaml          # 계정 프로필
├── posts/                # 발행된 글 아카이브
│   └── {date}_{slug}.md  # 개별 포스트
├── stances.yaml          # 주제별 입장/의견 레지스트리
└── topics-history.yaml   # 다룬 주제 이력
```

## Profile Schema

### Required Fields
| Field | Type | Description |
|-------|------|-------------|
| `id` | string (kebab-case) | 고유 식별자, 디렉토리명과 동일 |
| `name` | string | 계정 표시명 |
| `domain` | string | 주제 영역 (tech, finance, health, lifestyle 등) |
| `target_audience` | string | 타겟 독자 설명 |
| `tone` | string | 톤/말투 가이드 (자유 텍스트) |
| `language` | string | 주 사용 언어 (기본값: ko) |

### Optional Fields
| Field | Type | Description |
|-------|------|-------------|
| `hashtag_strategy` | string[] | 해시태그 전략 |
| `posting_frequency` | string | 포스팅 빈도 (예: "daily", "3/week") |
| `reference_accounts` | object[] | 레퍼런스 계정 (각 항목: handle, note) |
| `content_pillars` | string[] | 콘텐츠 핵심 주제 (3~5개 권장) |
| `avoid_topics` | string[] | 다루지 않을 주제 |
| `style_examples` | string[] | 말투/스타일 예시 텍스트 |

### Example Profile

```yaml
id: tech-insider
name: 테크 인사이더
domain: tech
target_audience: 20-30대 개발자, IT 종사자, 테크 얼리어답터
tone: |
  반말 사용. 짧고 임팩트 있게.
  전문 용어 자연스럽게 섞되 어려운 개념은 비유로 풀어서.
  "~한다", "~임" 체. 감탄사 적절히 ("ㄹㅇ", "미쳤다" 등).
language: ko
content_pillars:
  - AI/ML 트렌드
  - 개발자 생산성 도구
  - 스타트업 인사이트
  - 테크 뉴스 해석
hashtag_strategy:
  - "#개발자"
  - "#AI"
  - "#테크"
posting_frequency: daily
reference_accounts:
  - handle: "@techcrunch_threads"
    note: 뉴스 속보 스타일 참고
  - handle: "@developer_weekly"
    note: 개발자 타겟 톤 참고
avoid_topics:
  - 정치
  - 종교
style_examples:
  - "GPT-5 나왔는데 진짜 다름. 코딩 테스트 풀어봤더니 시니어급임. 근데 가격이..."
  - "요즘 cursor 안 쓰는 개발자 있음? 생산성 2배는 올라감. 근데 의존성 높아지는 건 좀 걱정."
```

## Stances Registry (stances.yaml)

계정이 표명한 입장/의견을 추적하여 일관성을 유지한다.

```yaml
react-vs-vue:
  stance: "React 선호, 생태계와 채용시장 기준"
  first_mentioned: 2026-03-10
  posts: ["2026-03-10_react-vs-vue.md"]

ai-replacing-devs:
  stance: "대체가 아닌 augmentation, 주니어에게 특히 유리"
  first_mentioned: 2026-03-12
  posts: ["2026-03-12_ai-future.md"]
```

- 새 글 작성 시 관련 stance가 있으면 반드시 참조
- 입장이 바뀔 경우: 이전 stance를 삭제하지 말고, `evolved_from` 필드로 변경 이력 추적
- stance key는 kebab-case, 검색 가능하도록 구체적으로

## Topics History (topics-history.yaml)

다룬 주제 이력을 관리하여 중복 방지한다.

```yaml
- topic: "AI 코딩 도구 비교"
  date: 2026-03-16
  angle: "생산성 관점"
  post: "2026-03-16_ai-coding-tools.md"
- topic: "React vs Vue 2026"
  date: 2026-03-10
  angle: "채용시장 데이터 기반"
  post: "2026-03-10_react-vs-vue.md"
```

## Post Archive (posts/)

발행된 글의 원문과 메타데이터를 보관한다.

파일명: `{YYYY-MM-DD}_{slug}.md`

```markdown
---
topic: "AI 코딩 도구 비교"
date: 2026-03-16
angle: "생산성 관점"
key_claims:
  - "Cursor가 현재 가장 완성도 높은 AI IDE"
  - "GitHub Copilot은 범용성에서 우위"
stances_referenced:
  - ai-coding-tools
hashtags: ["#AI", "#개발자", "#코딩"]
---

포스트 본문 전체...
```

## Commands

### `threads-account create`

대화형으로 새 계정 프로필을 생성한다.

**Flow:**
1. 사용자에게 필수 필드를 순서대로 질문 (id, name, domain, target_audience, tone, language)
2. 선택 필드도 하나씩 물어보되, 스킵 가능하게
3. 입력된 정보로 YAML 파일 생성 전 미리보기 표시
4. 사용자 컨펌 후 `accounts/{id}/profile.yaml`에 저장
5. `accounts/{id}/posts/`, `accounts/{id}/stances.yaml`, `accounts/{id}/topics-history.yaml` 초기화

**Validation:**
- id는 kebab-case만 허용
- 이미 동일한 id의 디렉토리가 존재하면 에러: "이미 존재하는 계정입니다: {id}"
- 필수 필드 누락 시 에러 표시 후 재입력 요청

### `threads-account list`

등록된 모든 계정을 테이블로 표시한다.

**Flow:**
1. `accounts/` 디렉토리의 모든 서브디렉토리 스캔
2. 각 `profile.yaml`에서 id, name, domain, 포스트 수 추출
3. 마크다운 테이블로 출력

**Empty state:** "등록된 계정이 없습니다. `threads-account create`로 새 계정을 만드세요."

### `threads-account show <id>`

특정 계정의 전체 프로필을 출력한다.

**Flow:**
1. `accounts/{id}/profile.yaml` 파일 존재 확인
2. 존재하면 전체 내용을 보기 좋게 포맷팅하여 출력
3. 최근 포스트 5개, stance 수, 총 포스트 수 요약 포함
4. 미존재 시 에러: "계정을 찾을 수 없습니다: {id}"

### `threads-account update <id>`

기존 계정 프로필의 특정 필드를 수정한다.

**Flow:**
1. `accounts/{id}/profile.yaml` 로드
2. 현재 값을 보여주며 어떤 필드를 수정할지 질문
3. 변경할 필드만 업데이트, 나머지 유지
4. 변경 사항 미리보기 후 컨펌
5. 파일 저장

## Usage by Other Skills

다른 threads-* 스킬에서 계정 데이터를 사용하려면:
1. `~/.claude/skills/threads-account/accounts/{id}/profile.yaml` — 프로필 로드
2. `~/.claude/skills/threads-account/accounts/{id}/stances.yaml` — 입장 확인
3. `~/.claude/skills/threads-account/accounts/{id}/topics-history.yaml` — 주제 이력 확인
4. `~/.claude/skills/threads-account/accounts/{id}/posts/` — 최근 포스트 로드
