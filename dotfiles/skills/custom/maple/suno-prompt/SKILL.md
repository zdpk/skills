---
name: suno-prompt
description: Generate Suno v5 AI music prompts (≤500 chars) for MapleStory BGM arrangements. Styles - lofi, piano, musicbox, piano+musicbox. Triggers on "suno prompt", "suno-prompt", "수노 프롬프트", "음악 프롬프트", "lofi prompt", "피아노 프롬프트", "오르골 프롬프트", or any request to create Suno music generation prompts for MapleStory BGM content.
---

# Suno Prompt Generator

Generate Suno v5 instrumental prompts (≤500 chars) for MapleStory BGM arrangements.

## Input Parsing

Parse user input for these components (all optional except style):

```
/suno-prompt <map/scene> <style> [mood] [BPM] [key]
```

- **map/scene**: MapleStory map name or freeform scene description (Korean or English)
- **style**: `lofi` | `piano` | `musicbox` | `piano_musicbox`
- **mood**: cozy, dreamy, bittersweet, rainy, night, nostalgic, mysterious, uplifting, ambient, epic
- **BPM**: number (e.g., `80bpm`, `80`)
- **key**: musical key (e.g., `Dm`, `Eb`, `Am`)

Examples:
- `/suno-prompt 헤네시스 lofi dreamy 78bpm Dm`
- `/suno-prompt 엘리니아 piano bittersweet`
- `/suno-prompt 커닝시티 lofi rainy night`

## Metadata Lookup

If user provides a MapleStory map name, read `maple-bgm-library/map_visual_metadata.json` and search for matching map entry. Extract:
- `atmosphere` array → inform mood selection
- `description_en` → extract scene keywords
- `visual_elements.lighting`, `time_of_day`, `season` → enrich atmosphere phrase

If no metadata match, generate based on input keywords alone.

## Prompt Construction

Read `references/suno-v5-guide.md` for prompt structure and character budget.
Read `references/styles.md` for style-specific instrumentation and mood translations.

### Construction Order

```
[style/genre], [primary instrument], [secondary instruments], [texture/effects], [mood], [scene atmosphere phrase], [BPM], [key], Instrumental, no vocals, loop-friendly
```

### Rules

1. **≤500 characters** — count before output, trim if over
2. **Comma-separated descriptors** — no full sentences
3. **English only** — Suno performs best with English prompts
4. **One scene phrase** — e.g., "inspired by MapleStory Henesys peaceful village"
5. **Positive framing** — describe what to include, never what to avoid
6. **Front-load genre + instrument** — most important descriptors first

### Default BPM/Key (when not specified)

Select based on style + mood. See `references/styles.md` for guidelines.

## Output Format

Display the prompt text, then output structured JSON metadata:

~~~
**Suno v5 Prompt** (387/500 chars)

```
Lofi hip-hop instrumental, mellow Rhodes electric piano melody, dusty vinyl crackle, tape-saturated warmth, lazy boom-bap drums with subtle swing, low-pass filtered bass, cozy late-night study vibe, nostalgic game OST atmosphere inspired by MapleStory Henesys peaceful village, warm analog texture, 78 BPM, Dm, Instrumental, no vocals, loop-friendly
```

```json
{
  "style": "lofi",
  "mood": "dreamy",
  "bpm": 78,
  "key": "Dm",
  "map": "헤네시스",
  "char_count": 387,
  "tags": ["lofi", "game-ost", "maplestory", "henesys", "nostalgic"]
}
```
~~~

## Variations

When user asks for variations or alternatives:
- Generate 2-3 prompt variants with different mood/texture combinations
- Keep same style and map, vary mood modifiers and texture descriptors
- Label each variant (A, B, C)
