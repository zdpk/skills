---
name: threads-write
description: Write Threads post drafts using account tone, research data, and reference patterns. Integrates context for consistency. Triggers on "threads-write", "글 작성", "대본 작성", "draft", "포스트 작성".
---

# Threads Post Writer

Threads 포스트 자동 작성 파이프라인의 핵심 스킬. 모든 upstream 데이터를 통합하여 계정의 톤/말투로 포스트 초안을 생성하고, 사용자 피드백을 반영하여 최종 확정한다.

## Data Dependencies

```
~/.claude/skills/threads-account/accounts/{id}/
├── profile.yaml          # tone, style_examples, target_audience, avoid_topics 등
├── posts/                # 이전 포스트 아카이브
├── stances.yaml          # 입장 레지스트리
└── topics-history.yaml   # 주제 이력
```

### 필수 의존
- **threads-account**: 계정 프로필 (tone, style_examples, target_audience, hashtag_strategy, avoid_topics)
- **threads-context**: 컨텍스트 로드, 주제 중복 체크, 입장 모순 체크

### 선택 의존 (있으면 품질 향상, 없어도 동작)
- **threads-topic**: 선택된 주제 및 angle
- **threads-reference**: 레퍼런스 분석 결과 (hooks, structure patterns)
- **threads-research**: 수집된 팩트, 검증된 주장, 통계 데이터

## Commands

### `threads-write draft <account-id>` -- 초안 생성

전체 파이프라인을 자동으로 오케스트레이션하여 초안을 생성한다.

**전체 Flow:**

```
1. 계정 프로필 로드 및 존재 확인
2. threads-context load {id}           ← 컨텍스트 자동 로드
3. 주제 확인 (사용자에게 주제/angle 질문 또는 threads-topic 데이터 활용)
4. threads-context check-topic {id} {topic}  ← 주제 중복 체크
   → 중복 발견 시: 다른 angle 제안, 진행 여부 확인
5. 입력 데이터 수집:
   - threads-reference 결과 (hooks, structure patterns)
   - threads-research 결과 (facts, claims, statistics)
6. 초안 작성 (아래 "톤 재현 규칙" 참조)
7. threads-context check-stance {id}    ← 입장 모순 체크
   → 모순 발견 시: 수정/발전/무시 선택
8. 초안을 사용자에게 제시
```

**Step 1: 계정 프로필 로드**
- `~/.claude/skills/threads-account/accounts/{id}/profile.yaml` 읽기
- 없으면: "계정을 찾을 수 없습니다: {id}. `threads-account create`로 먼저 생성하세요."

**Step 3: 주제 확인**
- 사용자가 주제를 직접 제시한 경우 그대로 사용
- threads-topic 데이터가 있으면 해당 주제/angle 활용
- 둘 다 없으면 사용자에게 질문: "어떤 주제로 작성할까요?"

**Step 5: 입력 데이터 수집**
- 리서치/레퍼런스 데이터가 없으면 해당 단계 스킵
- 있으면 초안에 적극 활용

---

### 톤 재현 규칙 (CRITICAL)

이 스킬의 핵심 품질 기준. 일반적인 AI 문체를 절대 사용하지 않는다.

**반드시 지켜야 할 것:**

1. **style_examples를 few-shot 예시로 취급**
   - 프로필의 style_examples에 있는 문장들의 패턴을 분석:
     - 어미 (임/함/다/요/ㅋㅋ)
     - 문장 길이 (짧은 문장 위주인지, 긴 설명인지)
     - 감탄사/구어체 표현 빈도
     - 이모지 사용 여부와 빈도
     - 문단 구분 방식
   - 이 패턴을 그대로 재현하여 초안 작성

2. **tone 필드를 보조 가이드로 활용**
   - tone에 "반말"이라면 반드시 반말
   - "짧고 임팩트 있게"라면 한 문장에 핵심 하나
   - "전문 용어 자연스럽게"라면 기술 용어를 설명 없이 사용

3. **절대 하지 말 것:**
   - "~입니다", "~합니다" 존댓말 (프로필이 반말 톤일 때)
   - "첫째, 둘째, 셋째" 나열식
   - "결론적으로", "요약하자면" 등 AI 전형 표현
   - 과도한 이모지 (프로필에 없으면 쓰지 않음)
   - 어색한 줄바꿈이나 bullet point 남용

---

### Threads 플랫폼 제약

| 항목 | 제한 |
|------|------|
| 단일 포스트 | 최대 500자 |
| 스레드 | 여러 포스트 연결 (각 500자) |
| 캐러셀 | 이미지 카드 형태 (각 카드에 텍스트) |

**형식 자동 판단:**
- 내용이 500자 이내 → 단일 포스트
- 500자 초과, 논점이 2~3개 → 스레드 (각 포스트가 하나의 논점)
- 비교/리스트형 → 캐러셀 제안
- 사용자가 형식을 지정하면 그에 따름

**스레드 분할 시 규칙:**
- 첫 포스트에 가장 강한 훅
- 각 포스트가 독립적으로도 의미 전달 가능
- 마지막 포스트에 CTA 또는 결론
- 파트 번호 표시: 1/, 2/, 3/ 등

---

### 미디어 구성 규칙

포스트에 첨부할 미디어를 구성한다. threads-research의 `media_sources`를 기반으로 각 포스트에 최적의 미디어를 배치한다.

**미디어 유형:**
| 유형 | 설명 | 예시 |
|------|------|------|
| `link_preview` | 기사 URL 첨부 → Threads가 자동 프리뷰 생성 | 뉴스 기사 링크 |
| `image` | 이미지 파일 직접 첨부 | 제품 사진, 성분표 사진, 공장 사진 |
| `user_provided` | 사용자에게 직접 제공 요청 | 직접 촬영한 제품 라벨 사진 |
| `stat_card` | 통계 수치를 텍스트 오버레이 이미지로 제작 제안 | "99.9% 중국산" 강조 카드 |

**미디어 배치 원칙:**
1. 훅 포스트: 충격적 통계 카드 or 기사 링크 (시선 끌기)
2. 팩트 포스트: 관련 뉴스 기사 링크 (신뢰도 부여)
3. 대안 포스트: 대안 제품 사진 (구매 전환)
4. 미디어 없는 포스트도 허용 — 텍스트만으로 충분하면 굳이 넣지 않음

**사용자 제공 요청 형식:**
미디어 중 직접 촬영이 필요한 경우:
```
📷 사용자 제공 필요:
- 포스트 3: 모산김치 제품 사진 또는 라벨 뒷면 사진
  → 원산지 표기가 보이는 사진이면 신뢰도 UP
```

---

### `threads-write revise` -- 수정

직전 초안에 사용자 피드백을 반영하여 수정본을 생성한다.

**Flow:**
1. 사용자의 수정 요청 확인
2. 직전 초안에 피드백 반영
3. 변경 사항 하이라이트하여 수정본 제시
4. 3회 이상 연속 수정 시 1차 초안 대비 누적 변경도 안내
5. 다시 리뷰 요청

**수정 시 톤 규칙:**
- 내용 수정 요청 → 톤은 유지
- 톤 변경 요청 → 프로필 기본 체계(반말/존댓말) 내에서 조정
- "더 짧게" → 핵심만 남기되 스타일 유지
- "더 길게" → 부연 추가하되 스타일 유지

---

## 초안 출력 형식

```
## 📝 초안

[포스트 1 본문]
  📎 미디어: {link_preview | image | stat_card | 없음} — {설명}

[포스트 2 본문]
  📎 미디어: ...

---
- 글자 수: 각 포스트별 {n}자 / 500자
- 형식: 단일 포스트 | 스레드 ({n}파트) | 캐러셀 ({n}장)
- 해시태그: {tags}
- 핵심 주장:
  1. {claim_1}
  2. {claim_2}
- 참조 stances: {referenced_stances or "없음"}
- 리서치 출처: {sources or "없음 (의견 기반)"}
- 미디어:
  - 포스트 1: {type} — {url or 설명}
  - 포스트 2: {type} — {url or 설명}
  - 📷 사용자 제공 필요: {있으면 설명}
---

수정이 필요하면 피드백을 주세요. 확정하려면 "확정"이라고 말씀해주세요.
```

## 최종 확정 출력 형식

```
## ✅ 최종 확정

### 본문 (복사용)
---
[포스트 본문 - 코드 블록으로 감싸서 복사 용이하게]
---

### 메타데이터
- 형식: {type}
- 글자 수: {n}자
- 해시태그: {tags}
- key_claims:
  - "{claim_1}"
  - "{claim_2}"
- 새 stances: {new_stances or "없음"}
- stances_referenced: {referenced or "없음"}

### 다음 단계
→ `threads-context save-post {id}` 로 아카이브하세요.
→ `threads-publish {id}` 로 발행하세요.
```

## avoid_topics 처리

- 프로필의 `avoid_topics`에 해당하는 내용이 주제나 리서치 데이터에 포함되면:
  1. 해당 내용을 초안에서 제외
  2. "프로필의 avoid_topics 정책에 따라 [{topic}] 관련 내용을 제외했습니다."로 안내
  3. 주제 자체가 avoid_topics에 해당하면 작성 전에 경고하고 진행 여부 확인

## 주의사항

- style_examples가 3개 미만이면: "style_examples가 부족합니다({n}개). `threads-account update {id}`로 추가하면 톤 재현 품질이 향상됩니다." 안내
- 리서치 데이터가 없으면 의견/경험 기반으로 작성하되, 구체적 수치/통계는 포함하지 않음
- 레퍼런스 패턴이 없으면 기본 구조(훅 → 본론 → CTA)로 작성
- stances.yaml, topics-history.yaml이 없으면 빈 상태로 처리 (신규 계정)
- 초안의 key_claims는 반드시 추출하여 check-stance와 최종 출력에 활용
