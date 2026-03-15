---
name: yt-research
description: Collect and structure research for YouTube video topics. Web search, summarize sources, extract claims with evidence, flag fact-check issues. Triggers on "yt-research", "리서치", "자료 수집", "research topic".
---

# YouTube Research — Topic Research Automation

Collect references, structure claims with evidence, and flag fact-check issues for YouTube video topics. Output feeds into the `yt-script` skill for script writing.

## Workflow

```
topic input → web search (KO+EN) → source processing → structuring → fact-check flagging → output (JSON + brief)
```

## Input Parsing

Parse user input for these components:

```
yt-research "<topic>" [--depth quick|standard|deep] [--channel <channel_id>]
```

- **topic** (required): 영상 주제 — Korean or English
- **depth** (optional, default `standard`):
  - `quick` — 5min overview, 3-5 sources, surface-level claims
  - `standard` — thorough research, 5-10 sources, cross-referenced claims
  - `deep` — academic-level, 10-20 sources, full fact-check with contradictions
- **channel** (optional): Channel ID to load channel-specific config from `channels/{channel_id}/config.json`

Examples:
- `yt-research "양자 컴퓨팅의 현재와 미래"`
- `yt-research "AI 반도체 전쟁" --deep`
- `yt-research "일본 경제 버블" --channel tech-shorts`
- `리서치 "메이플스토리 20주년 역사"`
- `자료 수집 "한국 출산율 위기" --deep`

## Commands

- `yt-research "<topic>"` — standard depth research
- `yt-research "<topic>" --deep` — deep research
- `yt-research "<topic>" --quick` — quick overview
- `yt-research "<topic>" --channel <id>` — channel-specific research
- `yt-research list` — show recent research in `research/` directory
- `yt-research show <topic_slug>` — show research detail from saved JSON

## Phase 1: Web Search

Use `WebSearch` to find relevant sources. Run searches in both Korean and English for broader coverage.

### Search Strategy

1. **Primary search**: Topic as-is in original language
2. **Translated search**: Topic translated to the other language (KO↔EN)
3. **Targeted searches**: Append qualifiers based on depth:
   - `quick`: `"{topic}"`, `"{topic} 정리"`, `"{topic} summary"`
   - `standard`: Add `"{topic} 통계"`, `"{topic} statistics"`, `"{topic} 논란"`, `"{topic} timeline"`
   - `deep`: Add `"{topic} 논문"`, `"{topic} research paper"`, `"{topic} official report"`, `"{topic} 반론"`

### Source Prioritization

Rank sources by type (highest to lowest reliability):

1. **official** — Government reports, official documentation, press releases
2. **academic** — Papers, journal articles, university publications
3. **news** — Major news outlets (Reuters, AP, 연합뉴스, etc.)
4. **wiki** — Wikipedia, 나무위키 (cross-reference required)
5. **video** — YouTube transcripts, documentary clips
6. **blog** — Expert blogs, Medium, Brunch
7. **community** — Reddit, forum posts (low reliability, use for sentiment only)

### Source Count by Depth

- `quick`: 3-5 sources
- `standard`: 5-10 sources
- `deep`: 10-20 sources

## Phase 2: Source Processing

Use `WebFetch` to get full content for each discovered source.

For each source, extract:

- **Key claims/facts**: Factual statements that can be verified
- **Statistics/numbers**: Any quantitative data with context
- **Quotes**: Direct quotes from named individuals
- **Dates**: Events, deadlines, milestones
- **Proper nouns**: People, organizations, places — spelling must be verified

### Extraction Rules

- Always note the exact location (paragraph, section) where data was found
- Preserve original language for quotes; add translation if needed
- Flag any claim that appears in only one source
- Note when a source cites another source (trace to origin when possible)

## Phase 3: Structuring

Organize all collected data into the following JSON structure:

```json
{
  "topic": "주제명",
  "topic_en": "Topic in English",
  "depth": "standard",
  "created_at": "2026-03-16T14:30:00+09:00",
  "summary": "1-2 paragraph overview of the topic covering the most important findings and context.",
  "claims": [
    {
      "id": "claim_001",
      "statement": "주장 내용",
      "statement_en": "Claim in English",
      "category": "fact|opinion|prediction|historical",
      "evidence": [
        {
          "source_id": "src_001",
          "excerpt": "근거 발췌",
          "excerpt_en": "Evidence excerpt in English",
          "reliability": "high|medium|low"
        }
      ],
      "contradictions": [
        {
          "source_id": "src_003",
          "excerpt": "반론 내용",
          "detail": "How this contradicts the claim"
        }
      ],
      "fact_check_flags": ["claim_flag_id_if_any"]
    }
  ],
  "sources": [
    {
      "id": "src_001",
      "title": "출처 제목",
      "url": "https://...",
      "type": "news|academic|official|blog|wiki|video|community",
      "date": "2026-01-15",
      "language": "ko|en",
      "reliability": "high|medium|low",
      "author": "Author name if available",
      "publisher": "Publisher/outlet name"
    }
  ],
  "timeline": [
    {
      "date": "2024-01",
      "event": "사건 설명",
      "event_en": "Event description",
      "source_id": "src_001"
    }
  ],
  "key_numbers": [
    {
      "value": "42%",
      "context": "맥락 설명",
      "context_en": "Context in English",
      "source_id": "src_001",
      "date": "2025-12"
    }
  ],
  "key_people": [
    {
      "name": "이름",
      "name_en": "Name in English",
      "role": "직함/역할",
      "relevance": "Why this person matters to the topic"
    }
  ],
  "fact_check_flags": [
    {
      "id": "flag_001",
      "claim_id": "claim_001",
      "issue": "single_source|outdated|conflicting|unverified|sensational|number_unverified",
      "detail": "설명",
      "severity": "high|medium|low",
      "recommendation": "Suggested action to resolve"
    }
  ]
}
```

## Phase 4: Fact-Check Flagging

Automatically detect and flag potential issues. Run these checks on every claim:

### Auto-Detection Rules

| Check | Trigger | Severity |
|-------|---------|----------|
| **Single source** | Claim supported by only 1 source | medium |
| **Outdated info** | Source date >1 year old for news/tech topics, >3 years for historical | medium |
| **Conflicting sources** | Two or more sources contradict each other | high |
| **Unverified numbers** | Statistics without clear original source | high |
| **Sensational language** | Exaggerated/clickbait phrasing in source | low |
| **Proper noun mismatch** | Name/title spelled differently across sources | medium |
| **Prediction as fact** | Future prediction presented as established fact | medium |
| **Missing date** | Claim references an event without specifying when | low |
| **Wiki-only** | Claim only found on Wikipedia/나무위키 | medium |
| **Circular sourcing** | Multiple sources trace back to same original report | high |

### Severity Levels

- **high** — Must verify before using in script. Could damage credibility if wrong.
- **medium** — Should verify. Add hedging language if used without verification.
- **low** — Note for awareness. Minor risk.

## Phase 5: Output

### File Output

Save results to the project directory:

- **Research JSON**: `research/{topic_slug}/research.json` — full structured data
- **Research Brief**: `research/{topic_slug}/brief.md` — human-readable summary

### Topic Slug Generation

Convert topic to filesystem-safe slug:
- Korean: Use romanization or short English equivalent
- Remove special characters, replace spaces with hyphens
- Lowercase, max 50 chars
- Example: `"양자 컴퓨팅의 현재와 미래"` → `quantum-computing-present-future`

### Brief Format (`brief.md`)

```markdown
# Research Brief: {topic}

**Depth**: {depth} | **Sources**: {count} | **Date**: {date}

## Summary
{1-2 paragraph overview}

## Key Claims
1. {claim} — [{reliability}] (source: {source_title})
2. ...

## Key Numbers
- {value}: {context} (source: {source_title}, {date})
- ...

## Timeline
- {date}: {event}
- ...

## Fact-Check Flags
### High Severity
- [{claim_id}] {detail} — {recommendation}

### Medium Severity
- [{claim_id}] {detail}

## Sources
1. [{title}]({url}) — {type}, {date}, {reliability}
2. ...
```

### Console Output

After saving files, display:
1. Summary paragraph
2. Claim count and source count
3. Fact-check flags (high severity highlighted)
4. File paths for saved output

## Multi-Channel Support

Load channel-specific config to adjust research behavior.

### Channel Config (`channels/{channel_id}/config.json`)

```json
{
  "channel_id": "tech-shorts",
  "name": "채널명",
  "default_depth": "standard",
  "topic_domains": ["tech", "science", "AI"],
  "tone": "casual|professional|educational",
  "language_priority": "ko|en|both",
  "research_preferences": {
    "prefer_korean_sources": true,
    "include_community_sentiment": false,
    "max_source_age_months": 12
  }
}
```

When `--channel` is provided:
- Load config and apply `default_depth` if no explicit depth given
- Filter sources by `topic_domains` relevance
- Adjust source language priority
- Apply `max_source_age_months` to outdated flagging threshold

## Integration

- **Input to `yt-script`**: Research JSON serves as the primary input for script generation. The script skill reads `research/{topic_slug}/research.json` directly.
- **Standalone use**: Can be triggered independently for general research without video production intent.
- **Pipeline**: `yt-research → yt-script → yt-thumbnail` (planned)

## Data Location

- Research output: `research/{topic_slug}/research.json`
- Research brief: `research/{topic_slug}/brief.md`
- Channel configs: `channels/{channel_id}/config.json`
