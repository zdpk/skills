---
name: maple-character
description: Generate MapleStory character sprite sheets (4-direction) using Google Flow with Nano Banana Pro. Automates browser to create chibi pixel art character sprites and saves to character registry. Triggers on "maple-character", "캐릭터 생성", "캐릭터 시트", "character sheet", "character sprite".
---

# MapleStory Character Sprite Sheet Generator

Generate MapleStory-style character sprite sheets (4-direction) using Google Flow's Nano Banana Pro via browser automation. Characters are saved to `character/` and registered in `character/index.json`.

## Input Parsing

```
/maple-character <name> <description_or_image> [sheet_type] [style]
```

- **name**: Character name (Korean or English)
- **description_or_image**: Text description of character OR path to reference image
- **sheet_type**: `body` (default) | `expression`
  - `body`: 4방향 전신 스프라이트 시트 (front, back, left, right)
  - `expression`: 표정 시트 — 동일 얼굴의 다양한 감정 표현
- **style**: `pixel_art` (default) | `chibi` | `semi_realistic`

Examples:
- `/maple-character 에아 "핑크 머리 엘프, 파란 탑+초록 스커트, 도적 클래스"`
- `/maple-character 에아 ea_solo.png expression`
- `/maple-character Luna ~/photos/luna_ref.png body chibi`
- `/maple-character 제니 jenny_concept.png expression pixel_art`

## Workflow

### Step 1: Parse Input

1. Extract character name, description/image path, sheet type, style option
2. If image provided, use as reference for character appearance
3. If text only, build character description for prompt
4. Determine sheet type: `body` (전신 4방향) or `expression` (표정 시트)

### Step 2: Build Character Sheet Prompt

Read `references/character-prompts.md` for prompt templates.

**Sheet type에 따라 다른 템플릿 사용:**

#### body (전신 시트)
- 4방향 전신 스프라이트 (front, back, left, right) 2x2 그리드
- Select style template: `pixel_art` / `chibi` / `semi_realistic`

#### expression (표정 시트)
- 동일 캐릭터 얼굴의 6~9가지 감정 표현 그리드
- 기본 표정: neutral, happy, sad, angry, surprised, embarrassed, smirk, crying, sleepy
- Select style template: `pixel_art` / `chibi` / `semi_realistic`
- 기존 캐릭터 이미지가 있으면 ingredient로 업로드하여 얼굴 일관성 유지

### Step 3: Browser Automation (Google Flow)

Follow the same browser workflow as `maple-style`. See `maple-style` skill's `references/flow-browser-workflow.md` for the complete step-by-step sequence.

**Summary:**
1. Navigate to Flow project -> "Images" tab -> "Create Image"
2. Verify "Nano Banana Pro" model
3. If reference image provided, upload via JS fetch injection:

```javascript
(async () => {
  const response = await fetch('<IMAGE_URL_OR_DATA_URI>');
  const blob = await response.blob();
  const file = new File([blob], 'ref.png', { type: 'image/png' });
  const input = document.querySelector('input[type="file"]');
  const dt = new DataTransfer();
  dt.items.add(file);
  input.files = dt.files;
  input.dispatchEvent(new Event('change', { bubbles: true }));
  return 'OK';
})();
```

4. After upload -> "Crop your ingredient" dialog -> click "Crop and Save"
5. Upload MapleStory character reference ingredients (from gallery if synced)
6. Type character sheet prompt -> click submit
7. Wait for generation (10-30s)
8. Download result

### Step 4: Download & Save

1. Download generated image via UI button (hover -> download icon) or JS fallback
2. Save convention:
   - body sheet: `character/<name>.png` (e.g., `ea_solo.png`)
   - expression sheet: `character/<name>_expr.png` (e.g., `ea_expr.png`)
   - If file exists, append version suffix: `<name>_v2.png`, `<name>_expr_v2.png`
3. Update `character/index.json` registry

### Step 5: Update Registry

Read current `character/index.json`, append new entry:

```json
{
  "name": "<한국어 이름>",
  "name_en": "<English name>",
  "file": "<filename>.png",
  "sheet_type": "<body|expression>",
  "description": "<character description>",
  "style": "<pixel_art|chibi|semi_realistic>",
  "created_at": "<ISO 8601 timestamp>"
}
```

### Step 6: Quota Management

If daily quota exhausted, use `/switch-google-account` to rotate to another Google account.

## Output

Report after generation:
- Character name and file path
- Prompt used
- Style applied
- Preview of saved character
- Updated registry entry count

## Data Location

- Character images: `character/<name>.png`
- Character registry: `character/index.json`
- Prompt templates: `maple-character/references/character-prompts.md`
