---
name: flow-ingredients-sync
description: Sync and manage Google Flow ingredient images across multiple Google accounts. Handles adding new ingredients to the master list, uploading to Flow, capturing UUIDs, and backfilling existing galleries. Triggers on "flow sync", "ingredient sync", "ingredient backfill", "flow backfill", "인그리디언트 싱크", "인그리디언트 백필", or when maple-style detects missing synced ingredients.
---

# Flow Ingredients Sync

Manage the master ingredient list and sync upload status across Google accounts for Google Flow.

## Data File

```
./maple-refs-library/flow_uploaded_ingredients.json
```

Schema v3 structure:
- `ingredients[]` — source of truth. 모든 레퍼런스 이미지의 마스터 목록.
- `accounts{}` — 계정별 sync 상태. 각 계정의 Flow project에 어떤 ingredient가 업로드되었는지, UUID는 무엇인지 추적.

## Commands

### 1. Add — 새 ingredient를 마스터 목록에 추가

```
/flow-ingredients-sync add <map_name> [category]
```

1. `map_visual_metadata.json`에서 map_id 조회
2. `ingredients[]`에 이미 있는지 `id` (`<map_slug>_<category>`) 로 중복 확인
3. 없으면 추가:

```json
{
  "id": "ellinia_minimap",
  "source_url": "https://maplestory.io/api/GMS/62/map/101000000/miniMap",
  "map_id": 101000000,
  "map_name": "엘리니아",
  "category": "minimap"
}
```

이 시점에서 어떤 계정에도 업로드하지 않음. 업로드는 `sync` 명령으로.

### 2. Sync — 현재 계정에 미싱크 ingredient 업로드

```
/flow-ingredients-sync sync [account_email]
```

1. `./google_accounts.json`에서 현재 활성 계정 확인 (또는 지정된 계정)
2. `ingredients[]` vs `accounts[email].synced` 비교 → 미싱크 목록 산출
3. 미싱크 ingredient 각각에 대해:
   a. Flow 프로젝트 페이지로 이동 (해당 계정의 `flow_project_id`)
   b. JS injection으로 이미지 업로드 → Crop and Save
   c. 갤러리 스캔하여 새 UUID 캡처 (기존 UUID diff)
   d. `accounts[email].synced`에 기록

UUID 캡처 방법:
```javascript
// 업로드 전: 기존 UUID 수집
const before = new Set();
document.querySelectorAll('button').forEach(btn => {
  const m = getComputedStyle(btn).backgroundImage.match(/image\/([a-f0-9-]+)\?/);
  if (m) before.add(m[1]);
});

// 업로드 + Crop and Save 후: 새 UUID 찾기
const after = [];
document.querySelectorAll('button').forEach(btn => {
  const m = getComputedStyle(btn).backgroundImage.match(/image\/([a-f0-9-]+)\?/);
  if (m && !before.has(m[1])) after.push(m[1]);
});
// after[0] 이 새로 업로드된 ingredient의 UUID
```

### 3. Backfill — 기존 갤러리에서 UUID 역매칭

```
/flow-ingredients-sync backfill [account_email]
```

계정의 Flow 갤러리에 이미 수동으로 업로드된 이미지들의 UUID를 수집하고, 가능한 한 `ingredients[]`와 매칭합니다.

1. Flow 프로젝트 페이지로 이동
2. "+" 버튼 클릭 → 갤러리 열기
3. 전체 UUID 스캔:

```javascript
const all = [];
document.querySelectorAll('button').forEach(btn => {
  const m = getComputedStyle(btn).backgroundImage.match(/image\/([a-f0-9-]+)\?/);
  if (m) all.push(m[1]);
});
JSON.stringify(all);
```

4. `synced`에 이미 있는 UUID 제외 → 미매칭 UUID 목록 산출
5. 미매칭 UUID에 대해:
   - 갤러리에서 해당 이미지를 시각적으로 확인 (screenshot + zoom)
   - `ingredients[]`의 어떤 항목과 매칭되는지 판단
   - 매칭되면 `synced`에 기록
   - 매칭 불가면 `synced`에 `"_unmatched_<uuid>"` 키로 기록 (수동 정리용)

### 4. Status — 현재 동기화 상태 리포트

```
/flow-ingredients-sync status
```

각 계정별로:
- 전체 ingredient 수
- synced 수 / 미싱크 수
- UUID null인 항목 수 (backfill 필요)
- flow_project_id 설정 여부

## Lazy-Load 모니터링

ingredient가 100개에 근접하면 반드시 DOM 렌더링 상태를 검증:

```javascript
const btns = [...document.querySelectorAll('button')]
  .filter(b => getComputedStyle(b).backgroundImage.includes('ai-sandbox-videofx'));
console.log(`DOM에 렌더링된 ingredient: ${btns.length}개`);
```

예상 전체 수와 불일치하면 lazy-load가 활성화된 것이므로, 스크롤 → 재스캔 반복 또는 대안 탐색 필요.

## Output

- 추가/업로드/매칭된 ingredient 목록
- 계정별 sync 상태 요약
- 실패/미매칭 항목 (있을 경우)
