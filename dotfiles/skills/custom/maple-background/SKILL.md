---
name: maple-background
description: Generate new MapleStory map backgrounds using Google Flow with Nano Banana Pro. Downloads original map renders from maplestory.io as reference, then generates new backgrounds that look like authentic new MapleStory maps. Triggers on "maple-background", "maple background", "배경 생성", "맵 배경", "background generate".
---

# MapleStory Background Generator

Generate new MapleStory-style map backgrounds that look indistinguishable from authentic in-game maps. Uses original map renders from maplestory.io as reference ingredients in Google Flow's Nano Banana Pro.

## Input Parsing

```
/maple-background <map_name_or_id> [description] [aspect_ratio]
```

- **map_name_or_id**: Korean/English map name OR numeric map ID from maplestory.io
  - Examples: `헤네시스`, `Henesys`, `100000000`, `Cloud Park`
- **description**: Optional scene modification description
  - Examples: `"밤 버전"`, `"눈 오는 날"`, `"새로운 구역"`
- **aspect_ratio**: `16:9` (default) | `9:16` | `1:1`

Examples:
- `/maple-background 구름공원 "새로운 구름 정원 맵" 16:9`
- `/maple-background 200010000 "야간 버전"`
- `/maple-background 헤네시스 "벚꽃이 피는 새로운 헤네시스 구역"`
- `/maple-background "Cloud Park" "floating garden with fountains"`

## Workflow

### Step 1: Find & Collect Map References

#### 1a. Search existing references

Check `maple-refs-library/places/` for already-downloaded map assets:

```bash
# Search by map name
find maple-refs-library/places/ -name "place.json" -exec grep -l "<map_name>" {} \;

# Or search by map ID
grep -r "<map_id>" maple-refs-library/places/*/place.json
```

Look for rendered map images in `assets/maps/` subdirectory:
- `map_<id>_render.png` — full map render from maplestory.io
- `map_<id>_render_1920.jpg` — resized JPEG version

#### 1b. Download if not found

If no matching map render exists, download from maplestory.io:

```bash
# Direct download of map render
curl -o "<dest_dir>/map_<map_id>_render.png" \
  -H "User-Agent: Mozilla/5.0" \
  "https://maplestory.io/api/KMS/389/map/<map_id>/render"
```

Or use the existing script for full asset collection:

```bash
python3 scripts/maple_refs_collect_assets.py \
  --place "<place_path>" \
  --only maps
```

#### 1c. Verify reference quality

Read the downloaded PNG to verify it's a valid map render (not an error page).
Display the image to the user for confirmation: "이 맵을 레퍼런스로 사용할까요?"

#### Common Map IDs

| Map | ID | Region |
|-----|----|--------|
| 헤네시스 | 100000000 | Victoria |
| 엘리니아 | 101000000 | Victoria |
| 페리온 | 102000000 | Victoria |
| 커닝시티 | 103000000 | Victoria |
| 리스항구 | 104000000 | Victoria |
| 오르비스 | 200000000 | Ossyria |
| 엘나스 | 211000000 | Ossyria |
| 루디브리엄 | 220000000 | Ossyria |
| 아쿠아리움 | 230000000 | Ossyria |
| 리프레 | 240000000 | Ossyria |
| 구름공원1 | 200010000 | Ossyria |
| 구름공원2 | 200020000 | Ossyria |
| 구름공원3 | 200040000 | Ossyria |
| 구름공원4 | 200050000 | Ossyria |
| 구름공원6 | 200080000 | Ossyria |

For unknown map IDs, query maplestory.io API:
```
https://maplestory.io/api/KMS/389/map/<map_id>
```
Response includes `name` (Korean map name).

### Step 2: Build Background Generation Prompt

Read `references/background-prompts.md` for prompt templates.

**Key principle**: The generated background must look like an authentic new MapleStory map — same pixel art style, same tile patterns, same color palette. NOT a reinterpretation or different art style.

Prompt structure:
1. Core style instruction (authentic MapleStory map replication)
2. Reference map context (what map is being used as base)
3. Variation description (what makes it a "new" map)
4. Technical requirements (aspect ratio, no characters, game-ready)

### Step 3: Browser Automation (Google Flow)

Follow `maple-style` skill's `references/flow-browser-workflow.md` for the complete step-by-step sequence.

**Summary:**
1. Navigate to Flow project → "Images" tab → "Create Image"
2. Verify "Nano Banana Pro" model
3. Set aspect ratio (default: 16:9 Landscape for backgrounds)
4. Upload map reference render(s) as ingredients via JS fetch injection:

```javascript
(async () => {
  const response = await fetch('file:///path/to/map_render.png');
  const blob = await response.blob();
  const file = new File([blob], 'map_ref.png', { type: 'image/png' });
  const input = document.querySelector('input[type="file"]');
  const dt = new DataTransfer();
  dt.items.add(file);
  input.files = dt.files;
  input.dispatchEvent(new Event('change', { bubbles: true }));
  return 'OK';
})();
```

**For local files**: Use `upload_image` tool with the ref parameter pointing to the file input, or convert local file to data URI first:

```javascript
// Alternative: read local file if fetch fails for file:// URLs
// Use the MCP upload_image tool instead for local files
```

5. After upload → "Crop your ingredient" dialog → click "Crop and Save"
6. Upload multiple reference renders (2-3 from same map area recommended)
7. Type background generation prompt → click "→" submit
8. Wait for generation (10-30s)
9. Download result

### Step 4: Download & Save

1. Download via UI hover → ⬇ → "Download 2K" (preferred for backgrounds)
2. Save to `background/` directory:
   - Naming: `<map_name_en>_<variant>.png`
   - Examples: `cloud_park_garden.png`, `henesys_cherry_blossom.png`
3. If file exists, append version: `_v2.png`, `_v3.png`

### Step 5: Register Output

Create/update `background/index.json`:

```json
{
  "name": "<descriptive name>",
  "file": "<filename>.png",
  "source_map": "<original map name>",
  "source_map_id": <map_id>,
  "description": "<what was generated>",
  "prompt": "<prompt used>",
  "references_used": ["<ref1_path>", "<ref2_path>"],
  "aspect_ratio": "16:9",
  "created_at": "<ISO 8601>"
}
```

### Step 6: Quota Management

If daily quota exhausted, use `/switch-google-account` to rotate accounts.

## Output

Report after generation:
- Generated background file path
- Source map references used
- Prompt used
- Preview of result
- Background registry entry

## Data Location

- Generated backgrounds: `background/<name>.png`
- Background registry: `background/index.json`
- Map references: `maple-refs-library/places/**/assets/maps/`
- Prompt templates: `references/background-prompts.md`
- Flow workflow: (shared with maple-style) see `maple-style` skill's `references/flow-browser-workflow.md`
