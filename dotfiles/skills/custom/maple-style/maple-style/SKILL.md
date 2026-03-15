---
name: maple-style
description: Transform any image into MapleStory in-game 2D pixel art style using Google Flow with Nano Banana Pro. Automates browser to upload reference images + input image via JavaScript fetch injection, generate MapleStory-style output, and download results. Triggers on "maple style", "maple-style", "메이플 스타일", "메이플 변환", "MapleStory style transfer", or any request to convert images into MapleStory visual style.
---

# MapleStory Style Image Generator

Generate MapleStory in-game style images from any input (photos, cartoons, sketches) using Google Flow's Nano Banana Pro via browser automation.

## Input Parsing

```
/maple-style <input_image_path_or_description> [map/scene] [aspect_ratio]
```

- **input**: Path to source image OR text description of desired scene
- **map/scene**: Optional MapleStory map name for reference style (Korean or English)
- **aspect_ratio**: `16:9` (default) | `9:16` | `1:1`

Examples:
- `/maple-style ~/photos/cafe.jpg 헤네시스`
- `/maple-style ./character.png 커닝시티 9:16`
- `/maple-style "rainy city street at night" 커닝시티`

## Workflow

### Step 1: Collect MapleStory References (with Sync Check)

If a map name is given:

1. Read `maple-refs-library/flow_uploaded_ingredients.json` (schema v3)
2. 현재 활성 계정 확인 (`./google_accounts.json` → `current_active`)
3. `ingredients[]`에서 해당 맵의 ingredient id 찾기 (예: `henesys_minimap`)
4. `accounts[현재계정].synced`에 해당 id가 있는지 확인:
   - **synced + UUID 있음** → 갤러리에서 UUID로 선택
   - **synced 안 됨** → `flow-ingredients-sync` 스킬로 sync 수행, 또는 직접 업로드
   - **ingredients에 없음** → `flow-ingredients-sync add`로 마스터 목록에 추가 후 sync

#### Selecting Existing Ingredient by UUID

```javascript
document.querySelectorAll('button').forEach(btn => {
  if (getComputedStyle(btn).backgroundImage.includes('TARGET_UUID')) btn.click();
});
```

Also check `maple-bgm-library/map_visual_metadata.json` for `image_generation_keywords` and `description_en` to enrich the prompt.

### Step 2: Build Style Transfer Prompt

Read `references/style-prompts.md` for prompt templates by category (background, character, item, scene).
Read `references/quota-and-models.md` for daily limits and model selection guidance.

### Step 3: Browser Automation (Google Flow)

Read `references/flow-browser-workflow.md` for complete step-by-step sequence.

**Critical: Upload ingredients via JavaScript injection (not native file picker)**

```javascript
// Upload image from URL as ingredient
(async () => {
  const response = await fetch('<IMAGE_URL>');
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

After each upload → "Crop your ingredient" dialog → click "Crop and Save".

**Summary:**
1. Navigate to Flow project → "Images" tab → "Create Image"
2. Verify "🍌 Nano Banana Pro" model
3. Upload references via JS fetch injection (repeat for each image)
4. Upload input image via same JS method (or select from gallery)
5. Type style transfer prompt → click "→" submit
6. Wait for generation (10-30s, progress % shown)
7. Hover image → click ⬇ download icon

### Step 4: Download

Two download methods (see `references/flow-browser-workflow.md` Step 9 for details):

1. **UI button** (primary): Hover image → ⬇ icon → "Download 1K" or "Download 2K"
2. **JS fetch** (fallback): Fetch image src → blob → anchor download

```javascript
// Fallback: JS download of generated image
(async () => {
  const img = document.querySelectorAll('img')[3]; // first generated image
  const r = await fetch(img.src);
  const b = await r.blob();
  const a = Object.assign(document.createElement('a'), {
    href: URL.createObjectURL(b), download: 'MapleStory_Generated.png'
  });
  document.body.appendChild(a); a.click(); a.remove();
})();
```

### Step 5: Quota Management

If daily image generation quota is exhausted, use the `switch-google-account` skill to switch to another Google account with remaining quota.

## Output

Report after generation:
- Number of images generated
- Prompt used
- Reference images used as ingredients
- Screenshot of results
