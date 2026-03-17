---
name: threads-reference
description: Discover, benchmark, and analyze reference Threads accounts. Market research, success pattern extraction, and competitive analysis. Triggers on "threads-reference", "레퍼런스 분석", "reference analyze", "성공 요인", "시장 조사", "벤치마크", "benchmark".
---

# Threads Reference Analyzer

Threads 시장 조사 + 레퍼런스 분석 스킬. 인기 계정 발굴부터 성공 패턴 심층 분석까지.

## Data Dependencies

```
~/.claude/skills/threads-account/accounts/{id}/
├── profile.yaml              # reference_accounts, domain 참조
└── references/               # 이 스킬이 생성/관리
    ├── discoveries/
    │   └── {domain}-{date}.yaml  # discover 결과
    ├── benchmarks/
    │   └── {handle}.yaml         # 계정별 심층 벤치마크
    ├── {handle}/
    │   ├── posts.yaml            # 수집된 포스트 원본 데이터
    │   └── last_scan.yaml        # 마지막 스캔 메타
    └── analysis.yaml             # 통합 분석 결과
```

## Commands

### `threads-reference discover <account-id>` — 인기 계정 발굴

해당 계정의 domain에서 Threads에서 잘 되고 있는 계정들을 찾아낸다.

**Flow:**
1. `profile.yaml`에서 domain, content_pillars 로드
2. WebSearch로 다음 쿼리들 실행:
   - `site:threads.net {domain} 인기 계정`
   - `threads 추천 계정 {domain} 팔로우`
   - `"{domain}" threads popular accounts followers`
   - `threads {content_pillar} 인플루언서`
   - `쓰레드 {domain} 추천 팔로우 2026`
3. 검색 결과에서 Threads 핸들 추출
4. 각 핸들에 대해 Chrome MCP로 프로필 페이지 접근:
   - 팔로워 수, 포스트 수, 계정 소개, 최근 포스트 3개
5. 팔로워 수 + 포스트 빈도 + 주제 관련성으로 점수화
6. 상위 10개 계정 리포트 출력
7. `references/discoveries/{domain}-{date}.yaml`에 저장

**출력 형식:**
```
## 🔍 Threads 인기 계정 발굴: {domain}

| 순위 | 핸들 | 팔로워 | 주제 | 특징 |
|------|------|--------|------|------|
| 1 | @handle1 | 52K | 식품 안전 | 뉴스형, 팩트 기반 |
| 2 | @handle2 | 38K | 건강 식품 | 추천형, 리뷰 |
| ... | | | | |

### 추천 레퍼런스 등록
위 계정 중 reference_accounts에 추가할 계정을 선택하세요.
→ `threads-account update {id}`로 추가 가능
```

**discoveries YAML 형식:**
```yaml
domain: health-food-safety
date: 2026-03-16
accounts:
  - handle: "@food_check_kr"
    followers: 52000
    posts_count: 340
    bio: "식품 안전 정보를 전달합니다"
    topic_match: 0.92
    sample_posts:
      - "마트에서 파는 OO, 뒷면 확인해보세요..."
      - "식약처 발표 정리해드립니다..."
    strengths:
      - "팩트 기반 콘텐츠"
      - "뉴스 해석형 포맷"
```

---

### `threads-reference benchmark <account-id> <handle>` — 계정 심층 벤치마크

특정 계정을 심층 분석하여 성공 요인을 체계적으로 분석한다.

**Flow:**
1. Chrome MCP로 `threads.net/{handle}` 접근
2. 최근 포스트 20~30개 수집 (텍스트, 인게이지먼트, 미디어, 날짜)
3. 다음 8가지 축으로 분석:

**분석 축:**

#### 1. 훅(Hook) 패턴
첫 줄의 관심 끌기 전략 분류:

| 유형 | 설명 | 예시 |
|------|------|------|
| `question` | 질문형 | "~해본 적 있음?" |
| `surprise` | 놀라움/충격 | "이거 알면 소름.." |
| `number` | 숫자/통계 | "99.9%가 중국산" |
| `story` | 경험담 | "어제 마트에서~" |
| `contrarian` | 반직관적 | "대기업 제품이 더 위험한 이유" |
| `trend` | 트렌드 | "요즘 ~가 난리" |
| `warning` | 경고형 | "절대 먹지 마세요" |
| `reveal` | 폭로형 | "아무도 말 안 하는 진실" |

#### 2. 글 구조
- `hook-fact-alternative-cta`: 훅 → 팩트 → 대안 → CTA (추천형)
- `hook-detail-cta`: 훅 → 상세 → CTA (정보형)
- `list-N-items`: N개 나열 (리스트형)
- `story-lesson`: 경험 → 교훈 (스토리형)
- `hot-take`: 강한 의견 한 줄 (어그로형)
- `thread-multi`: 여러 포스트 스레드

#### 3. 말투/톤
- 반말 vs 존댓말
- 감정 강도 (차분 / 보통 / 강렬)
- 이모지 사용 빈도
- 특징적 어미 ("~임", "~더라", "~한다" 등)
- 구어체 수준

#### 4. 스레드 구성
- 단일 포스트 vs 스레드 비율
- 스레드일 때 평균 몇 개로 구성
- 각 파트의 역할 (훅/상세/증거/대안/CTA)
- 스레드 vs 단일 포스트 인게이지먼트 비교

#### 5. 제품 추천 방식
- 직접 언급 ("OO 추천") vs 간접 ("이런 게 있더라")
- 링크 유도 방식 ("프로필 링크" / "댓글" / "DM")
- 추천 빈도 (전체 포스트 중 추천 포함 비율)
- 광고 표기 여부

#### 6. 미디어 활용
- 텍스트만 vs 이미지 vs 영상 vs 캐러셀
- 이미지 유형 (제품 사진 / 성분표 / 인포그래픽 / 기사 스크린샷)
- 미디어 유무별 인게이지먼트 차이

#### 7. 해시태그 전략
- 평균 개수
- 자주 사용하는 태그
- 위치 (끝 / 본문 중간 / 없음)
- 태그 수별 인게이지먼트 차이

#### 8. 포스팅 패턴
- 평균 빈도 (일/주 몇 개)
- 시간대 분포
- 요일별 패턴
- 인게이지먼트 높은 시간대

4. 벤치마크 결과를 `references/benchmarks/{handle}.yaml`에 저장
5. 분석 리포트 출력

**벤치마크 리포트 출력:**
```
## 📊 벤치마크 리포트: {handle}
팔로워: {N} | 분석 포스트: {M}개 | 평균 인게이지먼트: {avg}

### 훅 패턴
| 유형 | 빈도 | 평균 인게이지먼트 |
|------|------|-----------------|
| warning | 35% | 520 |
| surprise | 25% | 480 |
| ... | | |
→ 가장 효과적: {type} — "{example}"

### 글 구조
가장 많이 사용: {type} ({pct}%)
가장 효과적: {type} (인게이지먼트 {avg})

### 말투 분석
톤: {반말/존댓말} | 감정: {강도} | 이모지: {빈도}
특징적 어미: {list}
스타일 요약: "{한 줄 요약}"

### 스레드 구성
단일 포스트: {pct}% | 스레드: {pct}%
스레드 평균 길이: {N}개
인게이지먼트 비교: 단일 {avg1} vs 스레드 {avg2}

### 제품 추천
추천 포스트 비율: {pct}%
추천 방식: {direct/indirect}
링크 유도: {method}

### 미디어
텍스트만: {pct}% | 이미지: {pct}% | 영상: {pct}%
미디어 있을 때 인게이지먼트: +{pct}%

### 해시태그
평균 {N}개 | 위치: {placement}
주요 태그: {tags}

### 포스팅 패턴
빈도: 주 {N}회 | 최적 시간대: {time}

### 핵심 성공 요인 (Top 3)
1. {factor_1}
2. {factor_2}
3. {factor_3}

### 우리 계정에 적용할 점
- {actionable_1}
- {actionable_2}
- {actionable_3}
```

---

### `threads-reference scan <account-id>` — 레퍼런스 포스트 수집

계정의 모든 레퍼런스 계정 포스트를 수집한다.

**Flow:**
1. `profile.yaml`에서 `reference_accounts` 핸들 목록 추출
2. 각 레퍼런스 계정에 대해:
   a. WebSearch로 `site:threads.net {handle}` 검색하여 포스트 URL 확보
   b. Chrome MCP(navigate + get_page_text)로 각 포스트 페이지 접근
   c. 포스트 텍스트, 좋아요/댓글/리포스트 수, 게시일, 해시태그, 미디어 유무 파싱
   d. 계정당 최대 20개 포스트 수집
3. `references/{handle}/posts.yaml`에 저장
4. `references/{handle}/last_scan.yaml`에 스캔 메타 기록

**레퍼런스 계정 미등록 시:**
"레퍼런스 계정이 등록되지 않았습니다. `threads-reference discover {id}`로 먼저 인기 계정을 찾거나, `threads-account update {id}`로 직접 추가하세요."

---

### `threads-reference analyze <account-id> <topic>` — 주제별 성공 패턴 분석

수집된 레퍼런스 포스트를 특정 주제 기준으로 분석하여 성공 패턴을 추출한다.

**Flow:**
1. `references/` 하위의 수집 데이터 확인. 없거나 7일 이상 경과하면 자동으로 scan 실행.
2. 수집된 포스트 중 `<topic>` 관련 포스트 필터링
3. 인게이지먼트 합산 기준 상위 30%를 "성공 포스트"로 분류
4. 훅/구조/CTA/해시태그/인게이지먼트 패턴 분석
5. `references/analysis.yaml`에 저장
6. 분석 요약 출력

---

## 추천 워크플로우

```
1. threads-reference discover {id}          ← 니치에서 인기 계정 발굴
2. 마음에 드는 계정을 reference_accounts에 추가
3. threads-reference benchmark {id} {handle} ← 핵심 계정 심층 분석
4. threads-reference scan {id}              ← 전체 레퍼런스 포스트 수집
5. threads-reference analyze {id} {topic}    ← 특정 주제 성공 패턴 분석
6. → threads-write가 분석 결과를 글 작성에 활용
```

## threads-write 연동

`threads-write` 스킬은 글 작성 시 다음 순서로 분석 결과를 활용한다:

1. `references/analysis.yaml` 또는 `references/benchmarks/{handle}.yaml` 로드
2. `hooks.best_performing` 유형을 우선 적용
3. `structure` 중 가장 효과적인 패턴 채택
4. `cta` 최적 유형 삽입
5. `hashtags.common_tags`에서 관련 태그 선택
6. 말투/톤을 프로필 tone과 벤치마크 결과를 조합하여 결정

## 주의사항

- 수집은 공개 포스트만 대상. 비공개 계정은 건너뜀.
- Threads 웹 페이지 구조가 변경되면 파싱 로직 업데이트 필요.
- 인게이지먼트 수치는 수집 시점의 스냅샷. 절대값보다 상대적 순위에 의존.
- `references/` 디렉토리가 없으면 자동 생성.
- discover 결과는 검색 기반이므로 완벽하지 않음 — 수동으로 추가/제거 권장.
- benchmark는 시간이 오래 걸릴 수 있음 (포스트 20~30개 개별 접근).
