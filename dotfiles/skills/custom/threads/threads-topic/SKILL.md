---
name: threads-topic
description: Discover and score topics for Threads posts based on account domain, trends, and audience. Triggers on "threads-topic", "주제 발굴", "소재 찾기", "topic find".
---

# Threads Topic Discovery & Scoring

계정 도메인에 맞는 Threads 포스트 주제를 자동 발굴하고, 다축 점수 기반으로 최적의 소재를 선별하는 스킬.

## Data Dependencies

이 스킬은 다음 데이터에 의존한다:

```
~/.claude/skills/threads-account/accounts/{id}/
├── profile.yaml          # 계정 프로필 (domain, content_pillars, target_audience, avoid_topics)
└── topics-history.yaml   # 다룬 주제 이력 (threads-context 경유)
```

## Commands

### `threads-topic find <account-id>`

계정 도메인의 트렌딩 주제를 발굴하고, 점수를 매겨 순위별로 제시한다.

**Flow:**
1. `~/.claude/skills/threads-account/accounts/{id}/profile.yaml` 로드
2. domain, content_pillars, language를 조합하여 웹 검색 쿼리 생성
   - 각 content_pillar별로 최소 1개 쿼리 생성
   - 시간 범위 포함: "최근", "2026", "트렌드" 등 키워드 추가
   - language에 맞는 언어로 쿼리 작성
3. 웹 검색 실행 (WebSearch 도구 사용)
4. 검색 결과에서 주제 후보 추출 (최소 5개, 최대 15개)
5. **avoid_topics 필터링**: 프로필의 avoid_topics에 해당하는 주제 제거
6. **중복 감지**: topics-history.yaml을 로드하여 각 후보 주제와 대조
   - 동일/유사 주제가 있으면 "이미 다룸" 표시 후 하단 분리
   - 같은 주제라도 다른 angle이면 "다른 각도 가능" 표시
7. 각 후보에 대해 4축 점수 산출 (자동 score 적용)
8. 총점 내림차순 정렬하여 출력

**검색 쿼리 생성 예시:**
- domain: tech, content_pillars: ["AI/ML 트렌드", "개발자 생산성 도구"]
- → "AI ML 최신 트렌드 2026", "개발자 생산성 도구 추천 2026", "테크 뉴스 이번주"

**출력 형식:**
```
## 주제 발굴 결과: {account-name}

### 추천 주제
| 순위 | 주제 | 총점 | 관련 | 시의 | 독자 | 고유 | 트렌드 근거 |
|------|------|------|------|------|------|------|------------|
| 1 | GPT-5 출시 리뷰 | 88 | 9 | 10 | 9 | 8 | 오늘 발표, 테크 커뮤니티 화제 |
| 2 | Rust 2026 에디션 | 76 | 8 | 8 | 7 | 9 | 이번주 릴리즈, 주요 변경사항 다수 |
| ... | ... | ... | ... | ... | ... | ... | ... |

### 이미 다룬 주제 (재접근 가능)
| 주제 | 이전 날짜 | 이전 각도 | 제안 각도 |
|------|----------|----------|----------|
| AI 코딩 도구 비교 | 2026-03-16 | 생산성 관점 | 가격/비용 비교, 초보자 관점 |
```

**빈 상태:** "트렌딩 주제를 찾지 못했습니다. 검색 쿼리를 확장하여 재시도합니다..."

---

### `threads-topic score <account-id> <topic>`

특정 주제를 4축으로 점수화한다.

**Flow:**
1. 계정 프로필 로드 (domain, content_pillars, target_audience)
2. topics-history.yaml 로드 (uniqueness 판단용)
3. 웹 검색으로 해당 주제의 현재 트렌드 상태 확인 (timeliness 판단용)
4. 4축 점수 산출:

**점수 체계:**

| 축 | 가중치 | 평가 기준 |
|----|--------|----------|
| relevance (관련성) | 30% | domain, content_pillars와의 일치도 |
| timeliness (시의성) | 25% | 현재 트렌드/뉴스 관련도, 화제성 |
| audience_fit (독자 적합성) | 25% | target_audience의 관심사/지식 수준 부합도 |
| uniqueness (고유성) | 20% | topics-history 대비 새로움, 차별화 |

**총점 계산:**
```
총점 = (relevance × 30 + timeliness × 25 + audience_fit × 25 + uniqueness × 20) / 10
```

**출력 형식:**
```
## 주제 점수: "{topic}"

| 축 | 점수 | 근거 |
|----|------|------|
| 관련성 (relevance) | 9/10 | content_pillars의 'AI/ML 트렌드'에 직접 해당 |
| 시의성 (timeliness) | 10/10 | 오늘 발표된 뉴스, 소셜미디어 화제 |
| 독자 적합성 (audience_fit) | 8/10 | 개발자 타겟에 높은 관심사, 기술 수준 적합 |
| 고유성 (uniqueness) | 7/10 | 유사 주제 1건 있으나 다른 각도 가능 |

**총점: 86/100**
→ 추천: 작성 진행하세요.
```

**임계값:**
- 80점 이상: "강력 추천"
- 60-79점: "추천"
- 50-59점: "보통 — 각도를 잘 잡으면 가능"
- 50점 미만: "비추천 — 낮은 축 확인 필요" + 낮은 축 명시

## 파이프라인 연동

### threads 오케스트레이터에서의 위치
```
threads-account (프로필 로드)
  → threads-context (컨텍스트 로드)
    → threads-topic (주제 발굴/선정)    ← 이 스킬
      → threads-reference (레퍼런스 분석)
        → threads-research (심층 리서치)
          → threads-write (초안 작성)
            → threads-publish (발행)
```

### 입력
- threads-account: profile.yaml (domain, content_pillars, target_audience, avoid_topics, language)
- threads-context: topics-history.yaml (중복 감지용)

### 출력 (다음 스킬에 전달)
- 선정된 주제명
- 제안 angle
- 트렌드 근거 (참고 URL 포함)
- 점수 요약

## 주의사항

- 반드시 계정 프로필이 존재해야 실행 가능. 없으면: "계정을 찾을 수 없습니다: {id}. `threads-account create`로 먼저 계정을 생성하세요."
- topics-history.yaml이 없으면 빈 배열로 간주 (모든 주제가 uniqueness 만점)
- 웹 검색 실패 시: "웹 검색에 실패했습니다. 수동으로 주제를 입력하거나 재시도하세요."
- avoid_topics 필터링은 키워드 매칭 + Claude 판단 병행
- 점수는 참고용이며, 최종 주제 선택은 사용자가 결정
