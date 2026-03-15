---
name: maple-cover
description: Generate MapleStory-style cover images for BGM YouTube videos using Google Flow with Nano Banana 2. Use when the user wants to create cover art for MapleStory BGM tracks. Triggers on "maple cover", "메이플 커버", "커버 이미지", "BGM 커버".
---

# MapleStory BGM Cover Image Generator

Generates MapleStory-style cover images for YouTube BGM videos using Google Flow's Nano Banana 2. Builds prompts, collects map reference ingredients, and automates browser-based image generation.

## Style Reference

The output style MUST match MapleStory's in-game aesthetic:
- **2D side-scrolling pixel art** with layered parallax backgrounds
- **Chibi-proportioned characters** (large head, small body) — NPCs, monsters
- **Rich, warm color palettes** with soft ambient lighting
- **Tile-based platforms** and hand-painted backdrops
- **Cozy, lived-in atmosphere** — furniture, props, environmental storytelling
- Aspect ratio: **16:9** (1920x1080, YouTube thumbnail)
- NO text, NO UI elements, NO watermarks in the image

## Workflow

### Step 1: Identify the track

Read the user's request. They will provide either:
- A track name (e.g., "헤네시스", "엘리니아")
- A track ID (e.g., "bgm_0003")
- A region/area name

If a catalog exists at `maple-bgm-library/catalog.json`, look up the track metadata (map name, streetName, map ID) for reference.

### Step 2: Collect Reference Images

Gather map reference images to use as ingredients in Nano Banana 2:

1. Check `maple-refs-library/flow_uploaded_ingredients.json` for pre-synced ingredients
2. Check production `refs/` directory for already-collected references
3. If not available, download from maplestory.io:
   ```bash
   curl -o refs/map_render.png "https://maplestory.io/api/KMS/389/map/<map_id>/render"
   ```
4. Also check `maple-refs-library/places/` for pre-downloaded assets

Reference images serve as **style ingredients** in Nano Banana 2 to ensure the generated cover matches MapleStory's authentic look.

### Step 3: Build the scene

For each track, determine:

1. **Setting/Background**: The map's environment (forest, town, cave, beach, etc.)
2. **Time/Mood**: Match the BGM's mood (peaceful dawn, warm afternoon, mystical night, etc.)
3. **Characters**: 1-3 iconic NPCs or monsters from that area
4. **Props/Details**: Area-specific objects that add life to the scene

Use the MapleStory Area Reference below for known areas.

### Step 4: Generate the prompt

Output a prompt block like this:

```
## [트랙명] 커버 이미지

**Nano Banana 2 프롬프트:**

> [English prompt here]

**참고 몬스터/NPC:** [list]
**분위기:** [mood keywords]
**레퍼런스 ingredients:** [list of reference images used]
```

### Step 5: Browser Automation (Google Flow)

Follow `maple-style` skill's `references/flow-browser-workflow.md` for the complete step-by-step sequence.

**Summary:**
1. Navigate to Flow project → "Images" tab → "Create Image"
2. Verify "Nano Banana 2" model selected
3. Upload map reference images as ingredients via JS fetch injection
4. Upload character references if applicable
5. Type cover prompt → click "→" submit
6. Wait for generation (10-30s)
7. Download result (prefer "Download 2K" for cover images)
8. Save to production `images/` directory

### Step 6: Quota Management

If daily quota exhausted, use `/switch-google-account` to rotate accounts.

## Prompt Template

All prompts MUST follow this base structure (in English for Nano Banana 2):

```
A 2D side-scrolling pixel art scene in the style of MapleStory (the Korean MMORPG).
[SETTING DESCRIPTION].
[CHARACTER/MONSTER DESCRIPTION with chibi proportions].
[LIGHTING/MOOD DESCRIPTION].
The art style features: hand-painted layered backgrounds, tile-based platforms,
chibi-proportioned characters with large heads and small bodies,
warm saturated colors, soft ambient lighting, and rich environmental details.
16:9 aspect ratio, no text, no UI elements.
```

## MapleStory Area Reference

### Victoria Island Towns

**헤네시스 (Henesys)**
- Setting: Peaceful mushroom village, green hills, wooden houses, flower gardens, mushroom-shaped buildings
- NPCs: 마야 (Maya, pink hair girl), 빅 헤드워드 (Chief Stan)
- Monsters: 주황버섯 (Orange Mushroom), 파란달팽이 (Blue Snail), 슬라임 (Slime), 초록버섯 (Green Mushroom)
- Mood: Warm sunny afternoon, nostalgic, peaceful

**엘리니아 (Ellinia)**
- Setting: Enchanted treetop village, giant trees with houses built into them, magical floating platforms, fireflies, hanging bridges between trees
- NPCs: 그렌델 (Grendel the Really Old, wizard master), 페어리 (Fairy NPCs)
- Monsters: 초록버섯 (Green Mushroom), 슬라임 (Slime), 요정 (Evil Eye), 주니어 셀리온 (Jr. Cellion)
- Mood: Mystical twilight, ethereal glow, magical forest atmosphere

**페리온 (Perion)**
- Setting: Rugged mountain village, rocky terrain, ancient warrior statues, tribal architecture, orange/brown desert tones
- NPCs: 단스 (Dances with Balrog, warrior master)
- Monsters: 와일드보어 (Wild Boar), 스텀프 (Stump), 스톤골렘 (Stone Golem), 주니어 예티 (Jr. Yeti)
- Mood: Harsh sunset, dusty, warrior's resolve

**커닝시티 (Kerning City)**
- Setting: Urban underground city, neon signs, construction sites, sewer entrances, graffiti walls, dark alleys
- NPCs: 다크로드 (Dark Lord, thief master)
- Monsters: 옥토퍼스 (Octopus), 리게이터 (Ligator), 주니어 부기 (Jr. Boogie)
- Mood: Neon-lit night, urban gritty, mysterious

**커닝스퀘어 (Kerning Square)**
- Setting: Modern shopping mall, escalators, bright storefronts, colorful signs, fashion district
- Monsters: 매니킨 (Mannequin monsters), CD monsters
- Mood: Bright pop, modern, trendy

**리스항구 (Lith Harbor)**
- Setting: Seaside port town, wooden docks, ships, lighthouses, seagulls, ocean horizon
- NPCs: 올리비아 (Olovia), 선원들
- Monsters: 옥토퍼스 (Octopus), 조개 (Clam)
- Mood: Breezy afternoon, ocean wind, adventure departure

**슬리피우드 (Sleepywood)**
- Setting: Deep underground village in a giant cave, dim torch lighting, ancient stone buildings, mysterious shops
- NPCs: Sauna owner, potion shop NPCs
- Monsters: 드레이크 (Drake), 와일드카고 (Wild Cargo), 주니어 발록 (Jr. Balrog), 타우로마시스 (Taurospear)
- Mood: Dark, mysterious, ancient underground

### Victoria Island Dungeons

**드레이크의 동굴 (Drake's Cave)**
- Setting: Blue-tinted crystal cave, glowing minerals, underground lake
- Monsters: 이스트 드레이크 (Ice Drake), 다크 드레이크 (Dark Drake)
- Mood: Cold blue glow, mysterious depths

**루타비스 (Root Abyss)**
- Setting: Twisted dimensional garden beneath a massive tree root, surreal floating platforms
- Monsters: 피에르 (Pierre), 블러디 퀸 (Bloody Queen), 벨룸 (Vellum), 반반 (Von Bon)
- Mood: Dark, ominous, surreal beauty

### Adjacent Islands

**에레브 (Ereve)**
- Setting: Floating island above clouds, crystal palace, white marble architecture, blue sky, Shinsoo (divine beast)
- NPCs: 시그너스 (Cygnus, empress), 나인하트 (Neinheart)
- Monsters: 미미 (Mimi, small fairy creature)
- Mood: Majestic, serene, heavenly

**리엔 (Rien)**
- Setting: Frozen snowy island, ice caves, penguin village, frozen ships
- NPCs: 리린 (Lilin), 펭귄들
- Monsters: 펭귄 (Penguin), 예티 (Yeti)
- Mood: Cold, lonely, nostalgic winter

**골드비치 (Gold Beach)**
- Setting: Tropical beach resort, palm trees, golden sand, beach umbrellas, clear blue water
- Monsters: 코코넛 슬라임 (Coconut Slime), 게 (Crab)
- Mood: Bright summer, vacation, tropical

**플로리나 비치 (Florina Beach)**
- Setting: Tropical beach with colorful coral, clear water, small island
- Monsters: 루핀 (Lorang), 클랑 (Clang)
- Mood: Peaceful tropical paradise

**노틸러스 (Nautilus)**
- Setting: Giant submarine/ship interior and deck, mechanical elements, ocean view
- NPCs: 나인하트 관련, 선원들
- Mood: Adventurous, nautical, mechanical

**엘린숲 (Ellin Forest)**
- Setting: Ancient primeval forest, giant flowers, fairy village, time-displaced mystical woods
- NPCs: 엘린 요정들, 에피네아 (Ephenia)
- Monsters: 트리 요정 (Tree spirits), 독버섯 (Poison Mushroom)
- Mood: Ancient, mystical, fairy-tale

### Story/Variant Maps

**파괴된 헤네시스 (Destroyed Henesys)**
- Setting: Henesys in ruins, burning buildings, dark sky, destroyed mushroom houses
- Mood: Apocalyptic, tragic, dark contrast to peaceful original

**황혼의 페리온 (Twilight Perion)**
- Setting: Perion bathed in deep orange/purple twilight, crumbling warrior statues
- Mood: Melancholic sunset, end of an era

**시그너스의 정원 (Cygnus Garden)**
- Setting: Royal garden with blooming flowers, marble fountains, crystal gazebos
- NPCs: 시그너스 (Cygnus)
- Mood: Elegant, royal, serene

## Batch Mode

When the user requests multiple covers at once, output all prompts in sequence with clear headers. Group by region if applicable.

## Tips

- Always write prompts in English for best Nano Banana 2 results
- Be specific about MapleStory's unique pixel art style — reference "MapleStory (Korean MMORPG)" explicitly
- Include 1-3 recognizable monsters/NPCs per scene to make it feel authentic
- Match the BGM mood to the visual atmosphere (peaceful BGM = warm lighting, boss BGM = dramatic dark)
- For dungeon/boss areas, make the mood more dramatic and dark
- For town BGMs, keep it cozy and nostalgic
