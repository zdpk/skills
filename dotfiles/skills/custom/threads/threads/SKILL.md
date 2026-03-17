---
name: threads
description: Main orchestrator for Threads post automation pipeline. Chains topic discovery, research, writing, and publishing. Triggers on "threads", "threads full", "쓰레드", "쓰레드 포스트", "threads post".
---

# Threads Orchestrator

Threads 포스트 자동 작성 파이프라인의 메인 오케스트레이터. 개별 threads-* 스킬을 정해진 순서로 체이닝하며, 각 단계마다 사용자 확인을 받는다.

## Pipeline Overview

```
threads-account (계정 확인)
  → threads-topic (주제 발굴/선택)
    → threads-context load (컨텍스트 로드 + 주제 중복 체크)
      → threads-reference (레퍼런스 포스트 분석)
        → threads-research (데이터/팩트 수집 및 검증)
          → threads-write (초안 작성)
            → [사용자 리뷰/피드백 루프]
              → threads-publish (발행)
                → threads-context save-post (아카이브 + stances/topics 업데이트)
```

## Commands

### `threads full <account-id>` — 전체 파이프라인

9단계를 순서대로 실행한다. 각 단계 완료 후 결과를 요약하고 사용자 확인을 받는다.

**실행 순서:**

**Step 1: 계정 확인**
- `threads-account show <account-id>` 실행
- 계정 프로필(domain, tone, target_audience) 요약 표시
- "이 계정으로 진행할까요?" 확인

**Step 2: 주제 발굴**
- `threads-topic` 스킬 실행 — 계정의 domain과 content_pillars 기반으로 주제 후보 탐색
- 주제 후보 리스트 표시
- 사용자가 주제를 선택하거나 직접 입력

**Step 3: 컨텍스트 로드 + 중복 체크**
- `threads-context load <account-id> --topic <selected-topic>` 실행
- `threads-context check-topic <account-id> <selected-topic>` 실행
- 관련 이전 포스트, stances, topics-history 표시
- 중복 주제 경고가 있으면 표시하고 진행 여부 확인

**Step 4: 레퍼런스 분석**
- `threads-reference` 스킬 실행 — 선택된 주제에 대한 레퍼런스 포스트 분석
- 레퍼런스 요약(구조, 톤, 성과 패턴) 표시
- "레퍼런스 분석 결과를 반영하여 진행할까요?" 확인

**Step 5: 리서치**
- `threads-research` 스킬 실행 — 주제 관련 데이터, 통계, 팩트 수집 및 출처 검증
- 수집된 데이터와 출처 요약 표시
- "이 데이터를 기반으로 작성할까요?" 확인

**Step 6: 초안 작성**
- `threads-write` 스킬 실행 — 모든 컨텍스트(프로필, 주제, 레퍼런스, 리서치, stances)를 종합하여 초안 작성
- 전달할 컨텍스트:
  - 계정 프로필 (tone, target_audience, style_examples)
  - 선택된 주제와 각도
  - 레퍼런스 분석 결과
  - 수집된 데이터/팩트
  - 관련 기존 stances
  - 최근 포스트 톤 참조

**Step 7: 사용자 리뷰/피드백 루프**
- 초안 전문을 표시
- 사용자 선택지:
  1. **확정** → Step 8로 진행
  2. **수정 요청** → 피드백을 반영하여 Step 6 재실행
  3. **중단** → 파이프라인 종료 (현재까지의 컨텍스트 요약 출력)

**Step 8: 발행**
- `threads-publish` 스킬 실행
- 발행 결과(URL, 상태) 표시

**Step 9: 컨텍스트 업데이트**
- `threads-context save-post <account-id>` 실행 — 포스트 아카이브 저장 + stances/topics-history 자동 업데이트
- 업데이트된 항목 요약 표시
- "파이프라인 완료" 메시지 출력

---

### `threads topic <account-id>` — 주제 발굴만

계정을 확인한 후 주제 발굴 단계만 실행한다.

**Flow:**
1. `threads-account show <account-id>` — 계정 존재 확인
2. `threads-topic` 스킬 실행
3. 주제 후보 표시

---

### `threads write <account-id>` — 글 작성만

작성에 필요한 최소 단계를 실행한다. 주제가 이미 결정되어 있다고 가정하고, 사용자에게 주제를 물어본다.

**Flow:**
1. `threads-account show <account-id>` — 계정 확인
2. 사용자에게 주제/각도 질문 (또는 이전 대화에서 이어받기)
3. `threads-context load <account-id> --topic <topic>` — 컨텍스트 로드
4. `threads-context check-topic <account-id> <topic>` — 중복 체크
5. `threads-write` 스킬 실행
6. 리뷰/피드백 루프

---

### `threads publish <account-id>` — 발행만

확정된 초안이 있을 때 발행 단계만 실행한다.

**Flow:**
1. 현재 세션에 확정된 초안이 있는지 확인
2. 없으면 사용자에게 초안 입력 요청
3. `threads-publish` 스킬 실행
4. `threads-context save-post <account-id>` — 아카이브 + 업데이트

---

### `threads status <account-id>` — 계정 상태 확인

계정의 현재 상태를 한눈에 보여준다.

**Flow:**
1. `threads-account show <account-id>` — 프로필 로드
2. 다음 정보를 요약 표시:
   - 계정명, domain, target_audience
   - 총 포스트 수
   - 마지막 포스팅 일자
   - 최근 포스트 5개 (제목 + 날짜)
   - 등록된 stance 수
   - 최근 30일 주제 이력

**Output format:**
```
## 계정 상태: {name} ({id})
도메인: {domain} | 타겟: {target_audience}
총 포스트: {count}개 | 마지막 포스팅: {date}

### 최근 포스트
| 날짜 | 주제 | 각도 |
|------|------|------|
| ... | ... | ... |

### Stances ({count}개)
최근 추가: {latest-stance-key} ({date})

### 최근 30일 주제
- {date}: {topic}
- ...
```

---

## Step간 컨텍스트 전달 가이드

각 단계에서 다음 단계로 전달해야 하는 핵심 정보:

| From | To | 전달 정보 |
|------|----|----------|
| account | topic | domain, content_pillars, avoid_topics |
| topic | context | 선택된 주제(topic), 각도(angle) |
| context | reference | 주제 관련 이전 포스트, 관련 stances |
| reference | research | 레퍼런스의 데이터 인용 패턴, 부족한 데이터 영역 |
| research | write | 검증된 데이터/팩트/출처 목록 |
| context + reference + research | write | 프로필 톤, 주제, 레퍼런스 구조, 데이터, stances |
| write | publish | 확정된 초안 전문 |
| publish | context save-post | 발행된 포스트 본문, topic, angle, key_claims, stances |

## 에러 처리

- **계정 미존재**: "계정을 찾을 수 없습니다: {id}. `threads-account list`로 계정 목록을 확인하세요."
- **스킬 실행 실패**: 해당 단계에서 멈추고 에러 내용 표시. 사용자가 수동으로 해결 후 재시도하거나 스킵 선택 가능.
- **중간 중단**: 현재까지 완료된 단계와 수집된 컨텍스트를 요약 출력.

## 주의사항

- 각 스킬의 SKILL.md를 참조하여 해당 스킬의 지시사항을 따를 것
- 컨텍스트 윈도우 효율을 위해 각 단계 결과는 핵심 정보만 요약하여 유지
- 사용자가 "건너뛰기"를 요청하면 해당 단계를 스킵하고 다음으로 진행 (단, account와 write는 필수)
- 파이프라인 도중 사용자가 주제를 변경하면 context 로드부터 재시작
