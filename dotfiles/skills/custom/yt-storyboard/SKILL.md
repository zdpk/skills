---
name: yt-storyboard
description: Decompose YouTube scripts into visual storyboards with scene descriptions, image prompts, subtitle timing, and transition notes. Triggers on "yt-storyboard", "스토리보드", "storyboard", "씬 분해", "컷 분리".
---

# YouTube Storyboard — Script to Visual Scene Decomposition

Takes a finalized script and produces a structured scene-by-scene storyboard with all visual/audio specifications needed for video assembly.

## Input Parsing

Parse user input for these components:

```
yt-storyboard {script_id}
yt-storyboard "대본 텍스트" --channel <channel_id>
```

- **Script**: from `yt-script` output (`script.json`) or raw text
- **Channel ID**: for visual style defaults (reads from `channels/{channel_id}/config.json`)
- **Visual style**: `template-based` | `generative` | `hybrid`

When a script_id is provided, load `scripts/{channel_id}/{topic_slug}/script.json`. When raw text is provided, parse it as narration content directly.

## Scene Decomposition Rules

1. Each narration sentence = potential cut point
2. Group 1-3 sentences into one scene if they share visual context
3. Scene duration: min 2s, max 8s for shorts / max 15s for long-form
4. First scene must be visually impactful (matches hook)
5. Scene transitions should feel natural — avoid jarring visual jumps between related content

## Duration Estimation

- Korean narration speed: ~3.5 syllables/second (shorts), ~3.0 syllables/second (long-form)
- Auto-calculate scene duration from narration text length
- Flag scenes that exceed recommended duration for their type
- Total duration must match target format length

## Pipeline Steps

1. **Scene Split**: Break script into scenes based on content boundaries
2. **Visual Assignment**: Assign visual type/layout per scene
3. **Image Prompt Generation**: Create AI image prompts (English) for scenes needing generated images
4. **Subtitle Generation**: Create timed subtitle entries with highlight words
5. **Transition Planning**: Assign transitions between scenes
6. **Audio Planning**: BGM cues, SFX placement
7. **Camera Movement**: Assign camera movements per scene
8. **Asset List Compilation**: List all needed images, b-roll, icons, charts
9. **SRT Preview**: Generate subtitle file preview

## Scene Type Templates

### Hook Scene
- Bold text overlay, dynamic background, zoom-in camera
- Short duration (2-4s)
- Transition: cut or zoom

### Explanation Scene
- Diagram/infographic, text bullets, static camera
- Medium duration (4-8s)
- Transition: fade or slide

### Example Scene
- Real-world image/b-roll, minimal text, ken_burns camera
- Medium duration (3-6s)
- Transition: cut

### Comparison Scene
- Split screen layout, side-by-side elements
- Medium duration (4-8s)
- Transition: slide_left

### Chart/Data Scene
- Chart/graph visualization, number emphasis
- Medium duration (3-5s)
- Transition: fade

### Quote Scene
- Text-centered, subtle background, fade transition
- Short duration (3-5s)
- Transition: fade

### CTA Scene
- Subscribe/like graphics, channel branding
- Short duration (2-4s)
- Transition: slide_up

## Visual Style Presets

Each channel can define visual presets in `channels/{channel_id}/config.json`:

```json
{
  "visual_style": {
    "preset": "minimal|cinematic|infographic|meme|documentary",
    "color_palette": ["#1a1a2e", "#e94560"],
    "subtitle_style": "modern_bold|classic|typewriter|handwritten",
    "default_transitions": "cut|fade|slide",
    "background_preference": "dark|light|gradient|image_heavy",
    "text_density": "low|medium|high"
  }
}
```

When no channel config exists, use defaults: `minimal` preset, dark background, `modern_bold` subtitles, `cut` transitions.

## Output Format

Generate a storyboard JSON with this structure:

```json
{
  "storyboard_id": "sb_20260316_001",
  "script_id": "script_20260316_001",
  "channel_id": "tech-shorts",
  "format": "shorts",
  "aspect_ratio": "9:16",
  "total_duration_seconds": 52,
  "scenes": [
    {
      "scene_id": "scene_001",
      "scene_number": 1,
      "type": "hook|explanation|example|comparison|chart|quote|cta",
      "time_range": {
        "start": 0.0,
        "end": 3.2
      },
      "narration": {
        "text": "나레이션 텍스트",
        "word_count": 12,
        "estimated_duration_seconds": 3.2
      },
      "visual": {
        "description": "화면 설명 (한국어)",
        "layout": "full_image|split_screen|text_overlay|chart|comparison_lr|zoom_in|zoom_out",
        "background": {
          "type": "solid_color|gradient|image|video_loop|b_roll",
          "value": "#1a1a2e",
          "image_prompt": "AI 이미지 생성용 프롬프트 (English)",
          "b_roll_keywords": ["keyword1", "keyword2"]
        },
        "text_overlay": {
          "main_text": "화면에 표시할 핵심 텍스트",
          "sub_text": "",
          "position": "center|top|bottom",
          "style": "highlight|normal|emphasis|question"
        },
        "elements": [
          {
            "type": "icon|chart|arrow|number|image",
            "description": "요소 설명",
            "position": "center|left|right|top|bottom"
          }
        ]
      },
      "subtitle": {
        "text": "자막 텍스트",
        "highlight_words": ["강조할", "단어"],
        "style": "default|emphasis|whisper|shout"
      },
      "transition": {
        "type": "cut|fade|slide_left|slide_up|zoom|none",
        "duration_ms": 300
      },
      "audio": {
        "bgm_action": "continue|fade_in|fade_out|change|silence",
        "sfx": "whoosh|pop|ding|none",
        "sfx_timing": "scene_start|with_text|scene_end"
      },
      "camera": {
        "movement": "static|slow_zoom_in|slow_zoom_out|pan_left|pan_right|ken_burns",
        "focus_point": "center|text|subject"
      }
    }
  ],
  "global_settings": {
    "subtitle_style": {
      "font": "Pretendard Bold",
      "size": 48,
      "color": "#FFFFFF",
      "stroke": "#000000",
      "highlight_color": "#FFD700",
      "position": "bottom_third"
    },
    "bgm": {
      "track": "bgm_name_or_path",
      "volume": 0.15,
      "fade_in_seconds": 1.0,
      "fade_out_seconds": 2.0
    },
    "color_palette": ["#1a1a2e", "#16213e", "#0f3460", "#e94560"]
  },
  "asset_list": {
    "images_needed": [
      {
        "scene_id": "scene_001",
        "prompt": "AI generation prompt",
        "style": "realistic|illustration|diagram|infographic",
        "dimensions": "1080x1920"
      }
    ],
    "b_roll_needed": [
      {
        "scene_id": "scene_003",
        "keywords": ["technology", "server room"],
        "duration_seconds": 4
      }
    ],
    "icons_needed": ["chart_up", "warning", "lightbulb"],
    "charts_needed": [
      {
        "scene_id": "scene_004",
        "type": "bar|line|pie|comparison",
        "data_description": "차트 데이터 설명"
      }
    ]
  },
  "srt_preview": "1\n00:00:00,000 --> 00:00:03,200\n첫 번째 자막\n\n2\n..."
}
```

## Commands

- `yt-storyboard {script_id}` — generate storyboard from script
- `yt-storyboard "대본 텍스트" --channel tech-shorts` — from raw text
- `yt-storyboard adjust {storyboard_id} --scene 3 --visual "change to comparison layout"` — adjust specific scene
- `yt-storyboard assets {storyboard_id}` — show asset checklist
- `yt-storyboard srt {storyboard_id}` — export SRT only
- `yt-storyboard preview {storyboard_id}` — show visual preview (text-based scene descriptions)
- `yt-storyboard list` — show recent storyboards

## Output Location

- Storyboard JSON: `storyboards/{channel_id}/{topic_slug}/storyboard.json`
- Human-readable visual: `storyboards/{channel_id}/{topic_slug}/storyboard_visual.md`
- Subtitle file: `storyboards/{channel_id}/{topic_slug}/subtitles.srt`

## Integration

- **Reads from**: `yt-script` output (`scripts/{channel_id}/{topic_slug}/script.json`)
- **Feeds into**: `yt-compose` (video assembly), image generation skills
- **Channel config**: `channels/{channel_id}/config.json` for visual style presets
- **Image generation**: Image prompts can feed into `maple-cover`/`maple-background` skills or generic image generation
