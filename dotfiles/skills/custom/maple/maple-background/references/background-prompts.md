# MapleStory Background Generation Prompts

## Core Principle

The goal is NOT style transfer or reinterpretation. The goal is to generate a background that looks like it belongs in the actual MapleStory game — as if Nexon added a new map in a content patch. Same pixel art engine, same tile aesthetic, same color grading.

## Primary Prompt Template

```
Create a new MapleStory 2D side-scrolling game map background based on the reference ingredient images. This must look like an authentic in-game map — same pixel art tile style, same color palette, same visual language as the original MapleStory game. NOT a reinterpretation or different art style — it should be indistinguishable from a real MapleStory map screenshot.

Key requirements:
- Identical pixel art tile rendering as the reference maps
- Same cloud/ground/platform textures and patterns
- Same style of decorative objects (lampposts, arches, pavilions, vines)
- MapleStory's characteristic parallax background layers
- No characters, monsters, or UI elements — pure background only
- {variation_description}

This should look like a brand new map zone that was just added to the game — players should believe it's real.
```

## Variation Descriptions by Context

### Same Area, New Zone

For generating a new map in the same region (e.g., new Cloud Park map):

```
A new undiscovered area in the same region. Same environmental elements and color palette but with a slightly different layout and arrangement of platforms, structures, and decorations. It feels like walking into the next map in the sequence.
```

### Time of Day Variant

```
{time} version of this map area. Same exact tile style and objects, but with {lighting_description}. The atmosphere changes but the art assets remain MapleStory-authentic.
```

| Time | Lighting Description |
|------|---------------------|
| Night | deep blue-purple sky, warm yellow lamppost glow, starlit atmosphere, darker ground tones |
| Sunset | warm orange-pink sky gradient, golden hour lighting on tiles, long shadows |
| Dawn | soft pink-lavender sky, gentle morning mist, pale light on platforms |
| Storm | dark grey overcast sky, rain streaks, puddle reflections on platforms |

### Weather Variant

```
Same map but during {weather}. Identical tile style and structures with {weather_effects} added naturally.
```

| Weather | Effects |
|---------|---------|
| Snow | light snow layer on platforms, frost on structures, snowfall particles, white ground overlay |
| Rain | rain streaks, wet glossy platforms, puddles, darker sky |
| Cherry blossom | pink petal particles floating, sakura trees mixed with existing flora |
| Autumn | warm orange-red leaf colors replacing green, fallen leaves on ground |

### Expanded Area

```
A wider panoramic view expanding this map area. Same tile patterns and art style extended horizontally to fill a 16:9 landscape composition. More of the same environmental elements arranged in a natural, game-authentic way.
```

## Map-Specific Context Enrichments

### Cloud Park (Orbis) — 구름공원

```
Orbis Cloud Park map zone — floating cloud platforms in a bright blue sky. Key elements: fluffy white cloud platforms with green grass tops, Greek-style pavilions with red/green roofs and vine-covered columns, pink and silver balloon lampposts on golden poles, decorative golden arch gates, brown floating rock islands, green hanging vines. Bright, dreamy, celestial atmosphere with warm sunlight.
```

### Henesys — 헤네시스

```
Henesys village map zone — peaceful mushroom village. Key elements: green rolling grassy hills, mushroom-themed houses and structures, wooden fences and signposts, warm sunny afternoon lighting, scattered flowers and bushes, dirt paths, friendly small-town RPG atmosphere.
```

### Ellinia — 엘리니아

```
Ellinia treehouse forest map zone — enchanted forest canopy. Key elements: massive ancient trees with wooden platforms, rope bridges connecting treehouses, mystical green forest glow, moss-covered bark, magical fireflies and particles, deep forest atmosphere with filtered sunlight.
```

### Kerning City — 커닝시티

```
Kerning City urban map zone — dark underground city. Key elements: concrete platforms, neon signs, graffiti walls, subway infrastructure, sewer pipes, industrial metal structures, dark urban atmosphere with artificial lighting, rain-slicked surfaces.
```

### Ludibrium — 루디브리엄

```
Ludibrium toy castle map zone — whimsical toy world. Key elements: colorful building blocks as platforms, candy-striped structures, clockwork mechanisms, bright pastel colors, playful toy-themed decorations, floating geometric platforms.
```

### El Nath — 엘나스

```
El Nath mountain map zone — frozen snowy peaks. Key elements: icy blue-white platforms, snow-covered rocky terrain, sharp mountain peaks, frozen waterfalls, cold blue atmosphere, pine trees with snow, crystal ice formations.
```

## Aspect Ratio Guidelines

| Ratio | Use Case | Notes |
|-------|----------|-------|
| 16:9 | BGM video background (primary) | Most common, fills YouTube player |
| 9:16 | Mobile/Shorts background | Vertical format |
| 1:1 | Thumbnail or social media | Square crop |

## Tips for Authentic Results

1. **Multiple reference ingredients**: Upload 2-3 different map renders from the same area for style consistency
2. **Emphasize "same tile style"**: The AI tends to reinterpret — keep reinforcing "identical rendering"
3. **"NOT reinterpretation"**: Explicitly say what you don't want
4. **"Indistinguishable from real"**: This phrase helps anchor the generation
5. **No characters/UI**: Always specify background-only for clean results
6. **Nano Banana Pro required**: Other models won't match MapleStory's specific aesthetic
7. **Iterate**: First generation might be 70-80% accurate. Regenerate with refined description for better results
