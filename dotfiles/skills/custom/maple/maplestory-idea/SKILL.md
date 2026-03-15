---
name: maplestory-idea
description: MapleStory BGM remake idea manager. Manage BGM remake ideas through the production pipeline. Create, list, update ideas, add collab refs, generate Suno/cover prompts. Triggers on "maplestory-idea", "idea", "아이디어", "메이플 아이디어", "idea create", "idea list", "idea show", "maplestory-idea create", "maplestory-idea list", "maplestory-idea show", "아이디어 생성", "아이디어 목록".
---

# Idea Manager — BGM Remake Ideation Pipeline

Conversational wrapper around `scripts/idea_manager.py` for tracking MapleStory BGM remake ideas through music generation and image generation phases.

## Workflow

```
idea create → add collab refs → gen-suno → add suno output → gen-cover → add cover output → mark complete
```

## Input Parsing

Parse user input for the intended action. Common patterns:

- **Create**: `idea create 헤네시스 lofi dreamy` → create a lofi idea for 헤네시스
- **List**: `idea list`, `아이디어 목록` → show all ideas
- **Show**: `idea show <id>` → show idea detail
- **Suno**: `idea suno <id>` → generate suno prompt
- **Cover**: `idea cover <id>` → generate cover prompt

When user gives a map name in Korean, auto-resolve to the track ID by searching `maple-bgm-library/catalog.json`.

## Commands

All commands run `python3 scripts/idea_manager.py <subcommand>` from the project root.

### Create

```bash
python3 scripts/idea_manager.py create --track <track_id_or_name> --style <style> [--mood <mood>] [--bpm <bpm>] [--key <key>] [--notes <notes>]
```

- **track**: Track ID (`bgm_0003`) or Korean name (`헤네시스`) — auto-resolved from catalog
- **style**: `lofi`, `piano`, `musicbox`, `piano_musicbox`
- **mood**: Comma-separated keywords (dreamy, nostalgic, rainy, etc.)
- **bpm**: Target BPM (integer)
- **key**: Musical key (Dm, C, Am, etc.)

After creation, show the resulting `idea.json` summary.

### List

```bash
python3 scripts/idea_manager.py list [--status <status>] [--map <map_name>] [--style <style>]
```

Display as a formatted table. Status values: `draft`, `in_progress`, `music_done`, `image_done`, `complete`, `published`.

### Show

```bash
python3 scripts/idea_manager.py show <idea_id>
```

Display full idea detail including source, style, collab refs, prompts, outputs, and history.

### Update

```bash
python3 scripts/idea_manager.py update <idea_id> [--status <status>] [--title <title>] [--mood <mood>] [--bpm <bpm>] [--key <key>] [--notes <notes>]
```

### Add Collab Ref

```bash
python3 scripts/idea_manager.py add-collab <idea_id> --type <type> --title <title> [--title-en <en>] [--usage <usage>]
```

- **type**: `anime`, `game`, `movie`, `music`, etc.
- **usage**: How the reference influences the idea (e.g., "background atmosphere", "visual style")

### Generate Suno Prompt

```bash
python3 scripts/idea_manager.py gen-suno <idea_id> [--version <version>]
```

Generates a Suno prompt file at `ideas/<id>/prompts/suno_<version>.md` using:
- Idea style/mood/bpm/key
- Map visual metadata (atmosphere, lighting, season)
- Collab references

After generation, display the prompt and offer to refine or generate variants.

For richer prompts, invoke the `/suno-prompt` skill with the idea's parameters.

### Generate Cover Prompt

```bash
python3 scripts/idea_manager.py gen-cover <idea_id> [--version <version>]
```

Generates a cover prompt file using map visual metadata + collab refs.

#### Character Reference Selection

Before generating a cover image, offer character selection:

1. Read `character/index.json` to get available characters
2. Display character list to the user with name, file, and description
3. Let user select one or more characters to include in the cover
4. Record selected characters in the idea's `idea.json` under `image.characters`:

```json
{
  "image": {
    "characters": [
      { "name": "에아", "file": "character/ea_solo.png" }
    ]
  }
}
```

5. Include selected character files as reference ingredients when invoking `/maple-style` or `/maple-character`

If no characters are needed (e.g., landscape-only cover), user can skip selection.

For image generation, invoke the `/maple-style` or `/maple-cover` skills with the prompt and selected character references.

### Add Output

```bash
python3 scripts/idea_manager.py add-output <idea_id> --type <suno|cover> --file <path> [--prompt-version <version>]
```

Records a Suno MP3 or cover image output. Copies the file into the idea's `outputs/` directory.

### Reindex

```bash
python3 scripts/idea_manager.py reindex
```

Rebuilds `ideas/index.json` from all `idea.json` files.

## Dashboard View

When user asks for a dashboard or overview, run `list` and format as:

```
📋 Idea Dashboard
─────────────────────────────
Draft (2):
  • idea_20260216_143000 — 헤네시스 lofi 리메이크
  • idea_20260216_150000 — 엘리니아 piano 리메이크

In Progress (1):
  • idea_20260216_160000 — 커닝시티 lofi 리메이크 [suno v1 done]

Music Done (1):
  • idea_20260216_170000 — 페리온 musicbox 리메이크 [2 takes]
```

## Production Directory Setup

When an idea is ready for production (prompts finalized, moving to music/image creation), set up a production directory with all reference materials.

### Create Production Directory

```bash
python3 scripts/idea_manager.py setup-production <idea_id> [--date <YYYYMMDD>] [--slug <concept-slug>]
```

If the script doesn't support this yet, manually create the directory structure:

```
productions/{date}_{concept-slug}/
├── project.json          # metadata (single source of truth)
├── prompts/              # suno & cover prompts
├── music/                # source BGM + generated music
│   └── source_bgm.*     # original BGM from maple-bgm-library
├── images/               # generated cover images
├── video/                # final video output
└── refs/                 # reference materials
    ├── namuwiki/         # namuwiki screenshots
    └── npcs/             # NPC sprites (GIF)
```

### Reference Copying Checklist

When setting up a production directory, **always copy these references**:

#### 1. Source BGM (음악 원본)

Find the original BGM file from `maple-bgm-library/` using the track ID in `idea.json`:

```bash
# Search by track_id (e.g., bgm_0054)
find maple-bgm-library/ -name "*.mp4" -path "*<track_id>*"
# Or search by map name in catalog.json
```

Copy to: `productions/{slug}/music/source_bgm.mp4` (or `.mp3`)

#### 2. Map Reference Images (맵 레퍼런스)

Collect from multiple sources:

**a) maplestory.io renders** — full map render, composite, backdrop:
```bash
# Map render (full)
curl -o refs/map_render.png "https://maplestory.io/api/KMS/389/map/<map_id>/render"

# Check maple-refs-library/places/ for pre-downloaded assets
find maple-refs-library/places/ -name "place.json" -exec grep -l "<map_name>" {} \;
```

Copy matching renders/composites/backdrops to `refs/`.

**b) NPC sprites** — from `maple-refs-library/places/<place>/assets/npcs/`:
```bash
cp maple-refs-library/places/<place>/assets/npcs/*.gif refs/npcs/
```

**c) Namuwiki screenshots** — download from namuwiki map article:
```bash
# Parse namuwiki article for map screenshots
# Save to refs/namuwiki/
```

#### 3. Character References (캐릭터 레퍼런스)

If the idea uses characters (e.g., 아기 슬라임), copy sprite files:
```bash
cp character/<character_file> refs/
```

#### 4. Update project.json refs field

After copying, record all collected references in `project.json`:

```json
{
  "refs": {
    "backgrounds": ["refs/map_render.png", "refs/map_composite.png"],
    "npcs": "refs/npcs/ (N GIF sprites)",
    "namuwiki": ["refs/namuwiki/screenshot1.webp"],
    "characters": ["refs/slime.png"]
  }
}
```

### Workflow Integration

The full production workflow with reference copying:

```
idea create → add collab refs → gen-suno → gen-cover
  → setup production dir (copy refs: BGM + map images + NPCs + namuwiki + characters)
  → generate music (Suno) → add suno output
  → generate cover (Nano Banana 2) → add cover output
  → compose video → publish
```

## Integration with Other Skills

- **Suno prompt enrichment**: After `gen-suno`, suggest using `/suno-prompt` for a more detailed prompt
- **Cover generation**: After `gen-cover`, suggest using `/maple-style` for image generation with Nano Banana 2 (Google Flow)
- **Background generation**: Use `/maple-background` for generating new map backgrounds
- **Prompt iteration**: When user wants to refine, generate next version (v2, v3...) — never overwrite
- **Reference collection**: Use `/maple-background` workflow for downloading map renders from maplestory.io

## Data Location

- Ideas: `ideas/<idea_id>/idea.json`
- Index: `ideas/index.json`
- Prompts: `ideas/<idea_id>/prompts/`
- Outputs: `ideas/<idea_id>/outputs/`
- Productions: `productions/{date}_{concept-slug}/`
- Catalog: `maple-bgm-library/catalog.json`
- Visual metadata: `maple-bgm-library/map_visual_metadata.json`
- Map references: `maple-refs-library/places/`
- Characters: `character/`
