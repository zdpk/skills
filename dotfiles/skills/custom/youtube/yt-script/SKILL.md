---
name: yt-script
description: Generate and refine YouTube video scripts from research data. Supports shorts/long-form, channel tone templates, multi-stage refinement pipeline. Triggers on "yt-script", "대본", "스크립트", "script generate", "대본 작성".
---

# YouTube Script Generator

Takes research output (from yt-research) + channel config and produces production-ready scripts through a multi-stage refinement pipeline.

## Input Parsing

Parse user input for these components:

```
yt-script <topic> [--channel <id>] [--format <format>] [--from-research <path>] [--style <style>]
```

- **topic**: Video subject (Korean or English)
- **channel**: Channel ID matching `channels/{channel_id}/config.json` tone profile
- **format**: `shorts` (30-60s) | `standard` (3-8min) | `long` (8-20min)
- **from-research**: Path to existing yt-research output JSON
- **style**: `설명형` | `비교형` | `랭킹형` | `스토리텔링형` | `뉴스요약형`

Examples:
- `yt-script "AI 반도체 전쟁"` -- generate with defaults
- `yt-script "AI 반도체 전쟁" --channel tech-shorts --format shorts`
- `yt-script "AI 반도체 전쟁" --from-research research/ai_semiconductor`
- `yt-script refine script_20260316_001` -- run next pipeline stage
- `yt-script qa script_20260316_001` -- run QA checks only

When no channel is specified, prompt the user to select one or use the project default.

## Input Sources

1. **Research JSON from yt-research**: Structured data with claims, sources, fact-check results
2. **Raw topic + notes**: Free-form input when no research exists -- generate script directly from topic

If `--from-research` is provided, read the research JSON and extract:
- Key claims and their source IDs
- Fact-check flags and confidence levels
- Timeline/chronology data
- Statistics and quotes

## Script Structure Templates

### Shorts (30-60s)

```
1. 후킹 (0-3초): 질문/충격/호기심 유발
2. 문제 제기 (3-8초): 왜 이게 중요한지
3. 핵심 설명 (8-35초): 본론 1-3포인트
4. 예시/증거 (35-45초): 구체적 사례
5. 반전/재강조 (45-55초): 임팩트
6. CTA (55-60초): 구독/좋아요/다음 영상 예고
```

- Target word count: 150-200자
- Max sentence length: 25자
- Sections: 6

### Standard (3-8분)

```
1. 후킹 (0-15초): 강력한 오프닝
2. 채널 소개 (15-20초): 짧은 브릿지
3. 배경 설명 (20초-1분): 맥락
4. 본론 파트1 (1-3분): 핵심 내용
5. 본론 파트2 (3-5분): 심화/비교/예시
6. 본론 파트3 (5-7분): 반전/추가 정보
7. 요약 (7-7.5분): 정리
8. CTA (7.5-8분): 마무리
```

- Target word count: 800-2000자
- Max sentence length: 40자
- Sections: 8

### Long (8-20분)

```
1. 후킹 (0-15초): 강력한 오프닝
2. 채널 소개 (15-25초): 브릿지 + 영상 미리보기
3. 배경 설명 (25초-2분): 맥락 + 왜 지금 중요한지
4. 본론 파트1 (2-5분): 핵심 내용
5. 전환 (5-5.5분): 중간 브릿지 / 질문 던지기
6. 본론 파트2 (5.5-10분): 심화 분석
7. 본론 파트3 (10-14분): 사례/비교/반론
8. 인사이트 (14-17분): 종합 분석/전망
9. 요약 (17-19분): 핵심 정리
10. CTA (19-20분): 마무리 + 다음 영상 예고
```

- Target word count: 2000-5000자
- Max sentence length: 40자
- Sections: 10

## Multi-Stage Pipeline

Scripts go through sequential refinement stages. Each stage reads the previous output and produces the next version. Run stages in order; use `yt-script refine {script_id}` to advance to the next unfinished stage.

### Stage 1: 초안 (Draft)

- Research data -> rough script following the format template
- Focus on content completeness -- include all key claims
- All claims linked to source IDs from research
- Do not worry about length or tone yet
- Output key: `versions.draft`

### Stage 2: 압축 (Compression)

- Remove redundant sentences and filler
- Tighten every sentence -- cut unnecessary modifiers
- Enforce word count limits per format
- One paragraph = one point, no exceptions
- Merge overlapping claims
- Output key: `versions.compressed`

### Stage 3: 톤 보정 (Tone Adjustment)

- Load channel config from `channels/{channel_id}/config.json`
- Apply channel-specific voice: formality, 말투, persona
- Replace jargon with simple language matching the channel's audience
- Ensure consistent 말투 throughout (no mixing ~입니다 and ~해요)
- Remove AI-sounding phrases (see Writing Rules)
- Apply `preferred_expressions` from channel config
- Output key: `versions.tone_adjusted`

### Stage 4: 낭독 최적화 (Narration Optimization)

- Enforce max sentence length: 25자 for shorts, 40자 for standard/long
- Eliminate tongue-twisters and awkward consonant clusters
- Insert natural breathing points (marked with `/` in narration text)
- Convert numbers to reading format: use 만/억 units, spell out small numbers
- Add foreign word pronunciation notes in parentheses: `NVIDIA(엔비디아)`
- Ensure rhythm variation -- alternate short and medium sentences
- Output key: `versions.narration_optimized`

### Stage 5: 검수 (QA)

Run all checks and record results in `qa_result`:

- **금칙어 체크**: Scan against `tone.banned_words` from channel config
- **과장 표현 감지**: Flag superlatives and unsubstantiated claims
- **팩트체크 플래그 재확인**: Verify all claims still have valid source refs
- **저작권 위험 문구 체크**: Flag direct quotes longer than 2 sentences
- **CTA 존재 확인**: Verify CTA section exists and is not empty
- **길이 제한 확인**: Check total word count and per-sentence length
- **말투 일관성**: Verify no mixed speech levels

If all checks pass, copy `narration_optimized` to `versions.final`. If any fail, report issues and wait for user to fix or approve overrides.

Output key: `versions.final` + `qa_result`

## Channel Tone System

Each channel has a tone profile loaded from `channels/{channel_id}/config.json`:

```json
{
  "channel_id": "tech-shorts",
  "name": "채널명",
  "tone": {
    "formality": "casual|semi-formal|formal",
    "말투": "~입니다|~해요|~임|~다",
    "persona": "친근한 전문가",
    "banned_words": ["충격적인", "경악", "알고보니"],
    "preferred_expressions": [],
    "humor_level": "low|medium|high"
  },
  "format_defaults": {
    "primary": "shorts",
    "max_length_seconds": 59,
    "style": "설명형"
  }
}
```

When `--channel` is provided, read this config and apply throughout all pipeline stages. When not provided, use neutral semi-formal tone as default.

## Output Format

### Script JSON (`script.json`)

```json
{
  "script_id": "script_20260316_001",
  "topic": "주제",
  "channel_id": "tech-shorts",
  "format": "shorts",
  "style": "설명형",
  "version": "v3_narration",
  "duration_estimate_seconds": 52,
  "word_count": 180,
  "sections": [
    {
      "id": "hook",
      "type": "후킹",
      "time_range": "0:00-0:03",
      "narration": "대사 내용",
      "source_refs": ["claim_001"],
      "notes": "강한 톤으로"
    }
  ],
  "qa_result": {
    "banned_words_found": [],
    "exaggerations": [],
    "fact_check_warnings": [],
    "length_ok": true,
    "cta_present": true
  },
  "versions": {
    "draft": "...",
    "compressed": "...",
    "tone_adjusted": "...",
    "narration_optimized": "...",
    "final": "..."
  }
}
```

### Readable Script (`script_final.md`)

Generate a human-readable markdown version with:
- Title and metadata header
- Each section with time range, type label, and narration text
- Pronunciation notes inline
- Breathing marks shown as `[숨]`
- Source references as footnotes

## Output Location

- Script JSON: `scripts/{channel_id}/{topic_slug}/script.json`
- Readable version: `scripts/{channel_id}/{topic_slug}/script_final.md`
- Topic slug: lowercase, hyphens, no special chars (auto-generated from topic)

## Commands

### Generate

```
yt-script "주제"                                          -- generate with defaults
yt-script "주제" --channel tech-shorts --format shorts    -- specific channel/format
yt-script "주제" --from-research research/topic_slug      -- use existing research
yt-script "주제" --style 비교형                            -- specific style
yt-script "주제" --channel all                            -- generate for all channels
```

### Pipeline Control

```
yt-script refine {script_id}                -- run next pipeline stage
yt-script refine {script_id} --stage 3      -- run specific stage
yt-script qa {script_id}                    -- run QA checks only
```

### Format Conversion

```
yt-script convert {script_id} --format long    -- convert shorts to long-form
yt-script convert {script_id} --format shorts  -- condense long-form to shorts
```

### Management

```
yt-script list                              -- show recent scripts
yt-script list --channel tech-shorts        -- filter by channel
yt-script show {script_id}                  -- show script detail
```

## Writing Rules (Built-in)

These rules are enforced across all pipeline stages:

1. **첫 2초 후킹 필수** -- Hook must grab attention immediately; no soft openings
2. **한 문장 길이 제한** -- Shorts: 25자 max, Standard/Long: 40자 max
3. **쉬운 표현 치환** -- Replace jargon automatically (e.g., "양적 완화" -> "돈을 더 찍는 것")
4. **1문단 1포인트** -- Each paragraph covers exactly one point
5. **숫자 남발 금지** -- Max 2 numbers per section; round to meaningful units
6. **마지막 CTA 필수** -- Every script ends with a call to action
7. **과장 표현 제한** -- No unsubstantiated superlatives
8. **AI스러운 표현 금지** -- Ban list: "혁신적인", "놀라운", "충격적인", "획기적인", "경악", "알고보니", "실화냐", "레전드"

## Multi-Channel Support

When `--channel all` is used:
1. Read all configs from `channels/*/config.json`
2. Generate separate scripts for each channel
3. Save each to its own output directory: `scripts/{channel_id}/{topic_slug}/`
4. Display summary table showing all generated scripts

## Integration with Other Skills

- **Reads from**: `yt-research` output (research JSON with claims, sources, fact-checks)
- **Feeds into**: `yt-storyboard` (scene decomposition for video production)
- **Channel config**: `channels/{channel_id}/config.json`

## Data Location

- Scripts: `scripts/{channel_id}/{topic_slug}/script.json`
- Readable scripts: `scripts/{channel_id}/{topic_slug}/script_final.md`
- Channel configs: `channels/{channel_id}/config.json`
- Research input: `research/{topic_slug}/research.json`
