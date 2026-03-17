---
name: threads-research
description: Collect and fact-check information for Threads posts. Web search, source extraction, claim verification. Triggers on "threads-research", "자료 수집", "리서치", "팩트체크", "research collect".
---

# Threads Research

Threads 포스트 작성을 위한 자료 수집 및 팩트체크 스킬. 주제 선정 후, 글 작성 전에 실행하여 신뢰할 수 있는 근거 데이터를 확보한다.

## Data Dependencies

이 스킬은 `threads-account` 스킬이 관리하는 계정 프로필에 의존한다:

```
~/.claude/skills/threads-account/accounts/{id}/
├── profile.yaml          # domain, content_pillars 참조
└── stances.yaml          # 기존 입장 참조 (관련 주장 검증 시)
```

## Commands

### `threads-research collect <account-id> <topic>` -- 자료 수집

주제에 대한 웹 검색 기반 자료 수집을 수행한다.

**Flow:**
1. `~/.claude/skills/threads-account/accounts/{id}/profile.yaml` 로드
2. 계정의 domain, content_pillars, language를 참조하여 검색 맥락 구성
3. 주제 + 도메인 맥락을 조합하여 2-4개의 검색 쿼리 생성
   - 한국어 쿼리와 영문 쿼리를 병행
   - 다양한 각도: 개요, 비교, 최신 동향, 데이터/통계
4. WebSearch 도구로 각 쿼리 실행
5. 검색 결과에서 핵심 정보 추출:
   - 출처별: URL, 제목, 도메인 신뢰도 (high/medium/low)
   - 주장별: claim 텍스트, 근거(evidence), 출처 매핑
   - 수치 데이터: value, context, source, measured_at
6. 미디어 소스 수집:
   - 기사 링크: URL + 제목 + 핵심 인용문 1-2문장 + 썸네일 URL (있으면)
   - 관련 이미지: 공식 이미지, 차트, 인포그래픽 URL
   - 사용자 제공 필요 항목: 제품 사진, 직접 촬영 등 플래그
   - 통계 하이라이트: 포스트에 강조할 만한 수치 데이터 선별
7. 수집된 주장에 대해 자동으로 교차 검증 실행 (verify 로직)
8. 구조화된 결과 출력 (media_sources 섹션 포함)

**검색 쿼리 생성 예시:**
주제 "AI 코딩 도구 비교", 도메인 "tech"인 경우:
- "AI coding tools comparison 2026"
- "AI IDE 비교 Cursor Copilot 2026"
- "AI coding assistant market share statistics"
- "AI 코딩 도구 생산성 벤치마크"

**출처 신뢰도 분류:**
- `high`: 공식 기관, 주요 언론사, 공식 기술 블로그 (예: techcrunch.com, nature.com, official docs)
- `medium`: 전문 블로그, 기술 커뮤니티, 위키 (예: medium.com, dev.to, stackoverflow)
- `low`: 개인 블로그, 포럼, SNS (예: 개인 블로그, reddit, 트위터)

**Output format:**

```yaml
topic: "AI 코딩 도구 비교"
date: 2026-03-16
account: tech-insider

sources:
  - url: "https://example.com/article1"
    title: "AI Coding Tools Compared"
    credibility: high
  - url: "https://example.com/article2"
    title: "Cursor vs Copilot 벤치마크"
    credibility: medium

claims:
  - claim: "Cursor가 코드 완성 정확도에서 Copilot 대비 15% 높은 성능"
    evidence: "2026년 1분기 벤치마크 결과..."
    sources: ["https://example.com/article1", "https://example.com/article2"]
    verification_status: verified
  - claim: "GitHub Copilot 유료 사용자 수 1억 돌파"
    evidence: "GitHub 공식 발표..."
    sources: ["https://example.com/article1"]
    verification_status: partially_verified
    note: "단일 출처(공식 발표)만 확인"

stats:
  - value: "15%"
    context: "Cursor의 코드 완성 정확도 우위"
    source: "https://example.com/article1"
    measured_at: "2026 Q1"

media_sources:
  articles:
    - url: "https://example.com/article1"
      title: "AI Coding Tools Compared"
      excerpt: "기사 핵심 인용문 1-2문장"
      thumbnail_url: "https://example.com/thumb1.jpg"
      use_as: "link_preview"  # link_preview | quote_card | reference
    - url: "https://example.com/article2"
      title: "Cursor vs Copilot 벤치마크"
      excerpt: "벤치마크 결과 핵심 수치..."
      thumbnail_url: null
      use_as: "reference"
  images:
    - url: "https://example.com/chart.png"
      description: "AI IDE 시장 점유율 차트"
      source: "example.com"
      use_as: "attachment"  # attachment | carousel_card
    - query: "제품 비교 사진"
      description: "직접 촬영 또는 공식 제품 이미지 필요"
      use_as: "user_provided"  # 사용자에게 직접 제공 요청
  data_visuals:
    - type: "stat_highlight"
      value: "99.9%"
      context: "수입 김치 중 중국산 비율"
      suggestion: "텍스트 오버레이 이미지로 제작 권장"

summary: |
  AI 코딩 도구 시장에서 Cursor와 GitHub Copilot이 양강 구도.
  Cursor는 코드 완성 정확도에서 우위, Copilot은 범용성과 사용자 기반에서 우위.
  2026년 들어 AI IDE 시장이 급성장하며 새로운 경쟁자도 등장 중.

verification_report:
  total_claims: 5
  verified: 2
  partially_verified: 2
  unverified: 1
  conflicting: 0
  warnings:
    - "claim: 'X 주장' - 단일 출처만 확인. 글 작성 시 '~라는 보도가 있다' 형태 권장"
```

**에러 처리:**
- 계정 미존재: "계정을 찾을 수 없습니다: {id}"
- 검색 결과 없음: "'{topic}'에 대한 검색 결과가 부족합니다. 다른 키워드나 각도를 시도해보세요."

---

### `threads-research verify <claims>` -- 주장 검증

이미 수집된 주장 목록에 대해 교차 검증을 수행한다.

**Flow:**
1. 입력된 주장 목록 파싱
2. 각 주장에 대해:
   - 동일/유사 주장이 몇 개 출처에서 확인되는지 카운트
   - 상반되는 주장이 있는지 확인
   - 검증 상태 판정:
     - `verified`: 3개 이상 독립 출처에서 일치
     - `partially_verified`: 1-2개 출처에서 확인
     - `unverified`: 단일 출처, 다른 출처에서 미확인
     - `conflicting`: 출처 간 상반된 주장 존재
3. 검증 리포트 출력

**검증 리포트 출력:**
```
## 검증 결과

| 상태 | 수 |
|------|-----|
| verified | 3 |
| partially_verified | 2 |
| unverified | 1 |
| conflicting | 0 |

### 주의 필요 주장
- [unverified] "X 주장" -- 단일 출처만 확인
  -> 권장 표현: "~라는 보도가 있다", "~로 알려졌다"

- [conflicting] "Y 주장" -- 출처 간 상반
  -> 출처A: "..." vs 출처B: "..."
  -> 권장 표현: "~라는 의견과 ~라는 반론이 공존한다"

### 글 작성 가이드
- verified 주장: 단정적 표현 사용 가능 ("~이다", "~한 것으로 확인됐다")
- partially_verified 주장: 출처 언급 권장 ("~에 따르면")
- unverified 주장: 유보적 표현 필수 ("~라는 보도가 있다", "~로 알려졌다")
- conflicting 주장: 양쪽 관점 병렬 제시 또는 사용 자제
```

**미검증 주장 안전 표현 제안:**
unverified 또는 conflicting 주장을 글에 포함할 경우, 다음과 같은 안전한 표현 방식을 자동 제안한다:
- "~라는 보도가 있다"
- "~로 알려졌다"
- "~라는 주장도 있으나 확인이 필요하다"
- "일부에서는 ~라고 보고 있다"

## 다른 스킬에서의 사용 패턴

### threads-write에서 호출
```
1. threads-research collect {id} {topic}   <- 자료 수집 + 자동 검증
2. [리서치 결과를 threads-write에 전달]
3. threads-write가 verification_status를 참조하여 표현 수위 조절
```

### 단독 팩트체크
```
1. threads-research verify {claims}        <- 기존 주장에 대한 추가 검증
```

## 주의사항

- WebSearch 도구가 사용 불가능한 환경에서는 에러: "WebSearch 도구를 사용할 수 없습니다. 수동으로 자료를 제공해주세요."
- 리서치 결과는 파일로 저장하지 않음 (대화 컨텍스트 내에서 소비)
- 검증 결과는 참고용이며, 최종 판단은 사용자가 수행
- 검색 결과의 시의성에 주의 -- 오래된 정보일 수 있으므로 날짜 확인 필수
