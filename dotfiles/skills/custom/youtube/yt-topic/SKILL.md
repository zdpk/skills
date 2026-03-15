---
name: yt-topic
description: Discover and score YouTube video topics for any channel. Collects from channel-specific sources, scores by multiple criteria, selects top candidates. Triggers on "yt-topic", "소재", "주제 발굴", "topic find", "소재 찾기", "아이디어 수집".
---

# YouTube Topic Discovery

Multi-channel topic discovery system. Finds, scores, and selects video topic candidates using channel-specific sources and scoring criteria defined in `channels/{channel_id}/config.json`.

## Input Parsing

Parse user input for these components:

```
yt-topic [--channel <channel_id>] [--count <n>] [--mode <mode>]
```

- **channel** (required): Channel ID matching `channels/{channel_id}/config.json`
- **count** (optional, default `5`): Number of candidates to produce
- **mode** (optional, default `discover`):
  - `discover` -- new search from configured sources
  - `refresh` -- update scores for existing candidates
  - `review` -- show current candidates without new search

Examples:
- `yt-topic --channel incident-docs`
- `yt-topic --channel incident-docs --count 10`
- `소재 찾기 --channel econ-explain`
- `주제 발굴 --channel incident-docs --mode refresh`
- `아이디어 수집 --channel incident-docs --count 3`

## Commands

### Discovery

```
yt-topic --channel incident-docs                     -- discover 5 new topics (default)
yt-topic --channel incident-docs --count 10          -- find 10 candidates
yt-topic --channel incident-docs --mode refresh      -- refresh scores for existing candidates
yt-topic --channel all                               -- run discovery for all configured channels
```

### Listing & Viewing

```
yt-topic list --channel incident-docs                -- show all topics with status
yt-topic list --channel incident-docs --status candidate  -- filter by status
yt-topic show {topic_id}                             -- show topic detail
```

### Status Management

```
yt-topic select {topic_id}                           -- mark as selected (next pipeline stage)
yt-topic reject {topic_id} --reason "too similar"    -- reject with reason
```

## Channel-Specific Source Configuration

Sources are defined per channel in `channels/{channel_id}/config.json` under `topic_sources`. Each channel has its own primary sources, secondary sources, and search language preferences.

### Example: incident-docs channel

```json
{
  "channel_id": "incident-docs",
  "topic_sources": {
    "primary": [
      {"type": "osha_reports", "url": "https://www.osha.gov/fatalities", "description": "OSHA fatal accident reports"},
      {"type": "csb_reports", "url": "https://www.csb.gov/investigations/", "description": "Chemical Safety Board investigations"},
      {"type": "ntsb_reports", "url": "https://www.ntsb.gov/investigations/", "description": "Transportation safety investigations"},
      {"type": "wikipedia", "category": "Industrial_disasters", "description": "Wikipedia disaster/accident categories"}
    ],
    "secondary": [
      {"type": "reddit", "subreddits": ["CatastrophicFailure", "OSHA", "engineering_failures"]},
      {"type": "news_archive", "keywords": ["industrial accident", "factory explosion", "building collapse"]},
      {"type": "youtube_competitors", "channels": ["0시기록", "리뷰엉이"], "purpose": "duplicate_avoidance"}
    ],
    "search_languages": ["en", "ko"]
  }
}
```

### Example: econ-explain channel

```json
{
  "channel_id": "econ-explain",
  "topic_sources": {
    "primary": [
      {"type": "news", "keywords": ["경제", "금리", "환율", "인플레이션"]},
      {"type": "google_trends", "category": "business_finance"},
      {"type": "academic", "keywords": ["economics explained", "behavioral economics"]}
    ],
    "secondary": [
      {"type": "youtube_competitors", "channels": ["슈카월드", "삼프로TV"]},
      {"type": "reddit", "subreddits": ["economics", "explainlikeimfive"]}
    ]
  }
}
```

## Workflow

```
source config → source collection → enrichment → scoring → selection → output
```

### Phase 1: Source Collection

Use `WebSearch` to query each source configured in the channel's `topic_sources`.

For each source:
1. Query the source URL or search with configured keywords
2. Collect potential topics with:
   - Title/headline
   - Brief description
   - Source URL
   - Date
3. Respect `search_languages` -- run searches in all configured languages
4. Deduplicate across sources by title similarity and event identity

### Phase 2: Enrichment

For each deduplicated candidate, gather additional context:

- **Available source count**: How many independent sources cover this topic?
- **Competitor coverage check**: Already done by major channels in the competitor list?
- **Basic story outline**: Is there a clear narrative arc (beginning, middle, end)?
- **Visual potential assessment**: Can scenes be described and visualized?

Use `WebSearch` and `WebFetch` to fill gaps. Check competitor YouTube channels for existing coverage.

### Phase 3: Scoring

Score each candidate on channel-specific criteria. Channels can override weights in their config under `scoring_criteria`. Default scoring:

```json
{
  "scoring_criteria": {
    "story_quality": {
      "weight": 0.25,
      "description": "Clear narrative arc (beginning, middle, end)",
      "factors": ["has_timeline", "has_characters", "has_resolution"]
    },
    "visual_potential": {
      "weight": 0.15,
      "description": "Can scenes be clearly visualized?",
      "factors": ["describable_locations", "physical_processes", "diagrammable"]
    },
    "source_quality": {
      "weight": 0.20,
      "description": "Official reports, multiple corroborating sources",
      "factors": ["official_report_exists", "source_count", "source_reliability"]
    },
    "emotional_impact": {
      "weight": 0.15,
      "description": "Viewer engagement potential",
      "factors": ["relatability", "surprise_factor", "stakes"]
    },
    "uniqueness": {
      "weight": 0.15,
      "description": "Not already covered by major competitors",
      "factors": ["competitor_coverage", "fresh_angle_possible"]
    },
    "multilingual_potential": {
      "weight": 0.10,
      "description": "Relevant to EN/JP audiences too",
      "factors": ["international_event", "universal_theme", "en_sources_available"]
    }
  }
}
```

Each factor is scored 1-10. Weighted total produces the final score.

#### Channel-Specific Additional Criteria

Channels can define extra scoring criteria in their config. For example, `incident-docs` adds:

- **Investigation report available**: OSHA/CSB/NTSB official report exists (bonus +1.0)
- **Educational angle**: Clear safety lesson that adds value beyond entertainment
- **Ad-safety**: No excessive gore or content that would trigger ad restrictions (penalty if violated)

### Phase 4: Selection

1. Rank all candidates by total weighted score
2. Apply deduplication filter (remove near-duplicates, keep highest scorer)
3. Return top N candidates (N = `--count` parameter)

### Phase 5: Output

Display ranked candidates as a formatted table in console, then save structured output.

#### Console Output

Show a summary table:

```
# Topic Discovery: incident-docs (2026-03-16)
Sources queried: 8 | Raw candidates: 45 | After dedup: 32 | Final: 5

| Rank | Score | Title                        | Sources | Difficulty |
|------|-------|------------------------------|---------|------------|
| 1    | 8.4   | 주제 제목                      | 4       | medium     |
| 2    | 7.9   | 주제 제목                      | 3       | easy       |
| ...  |       |                              |         |            |

Saved to: topics/incident-docs/discoveries/2026-03-16.json
```

#### JSON Output

```json
{
  "discovery_id": "disc_20260316_001",
  "channel_id": "incident-docs",
  "date": "2026-03-16",
  "candidates": [
    {
      "rank": 1,
      "topic_id": "topic_001",
      "title": "주제 제목",
      "title_en": "English title",
      "summary": "1-2 sentence summary",
      "story_outline": "배경 -> 인물 -> 사건 -> 결과",
      "sources": [
        {"title": "OSHA Report #...", "url": "...", "type": "official_report"},
        {"title": "Wikipedia: ...", "url": "...", "type": "wiki"}
      ],
      "scores": {
        "story_quality": 8.5,
        "visual_potential": 7.0,
        "source_quality": 9.0,
        "emotional_impact": 8.0,
        "uniqueness": 9.5,
        "multilingual_potential": 8.0,
        "total": 8.4
      },
      "scoring_notes": "Official CSB report with full investigation. Strong narrative arc. Not covered by major KR channels.",
      "competitor_check": {
        "covered_by": [],
        "similar_topics": ["0시기록 -- 비슷한 사일로 사고 (2024)"]
      },
      "estimated_difficulty": "easy|medium|hard",
      "tags": ["industrial", "usa", "osha", "grain_silo"],
      "status": "candidate"
    }
  ],
  "search_meta": {
    "sources_queried": 8,
    "raw_candidates": 45,
    "after_dedup": 32,
    "after_scoring": 5
  }
}
```

## Topic Lifecycle

Topics progress through a pipeline shared with other yt-* skills:

```
candidate -> selected -> researched -> scripted -> produced -> published
               |            |             |           |
           (yt-topic)  (yt-research)  (yt-script)  (yt-compose)
```

Status transitions:
- `candidate` -- newly discovered, scored but not yet chosen
- `selected` -- chosen for production via `yt-topic select`
- `researched` -- deep research completed by `yt-research`
- `scripted` -- script generated by `yt-script`
- `produced` -- video assembled by `yt-compose`
- `published` -- uploaded and live

Rejected topics get status `rejected` with a reason field.

## Duplicate Avoidance

Three layers of duplicate checking:

1. **Own channel history**: Check against `topics/{channel_id}/index.json` for all past topics (any status)
2. **Competitor channels**: Search configured competitor channels' recent videos via `WebSearch` for `youtube_competitors` entries
3. **Cross-discovery dedup**: Within a single discovery run, remove near-duplicate topics (keep highest scorer)

When a similar-but-different-angle topic is found, flag it as `similar_topics` in `competitor_check` rather than discarding -- a fresh angle may still be viable.

## Multi-Channel Support

- Each channel has its own source config, scoring weights, and topic index
- `yt-topic --channel all` runs discovery for all channels with configs in `channels/*/config.json`
- Cross-channel topic sharing: when a topic discovered for one channel might fit another, note it in the output with `cross_channel_suggestion` field

## Output Location

- Discovery results: `topics/{channel_id}/discoveries/{date}.json`
- Topic index: `topics/{channel_id}/index.json` (all topics across all discoveries, with current status)
- Channel configs: `channels/{channel_id}/config.json`

### Topic Index Format (`index.json`)

```json
{
  "channel_id": "incident-docs",
  "topics": [
    {
      "topic_id": "topic_001",
      "title": "주제 제목",
      "status": "candidate",
      "score": 8.4,
      "discovered_at": "2026-03-16",
      "selected_at": null,
      "rejected_at": null,
      "rejection_reason": null,
      "discovery_id": "disc_20260316_001"
    }
  ]
}
```

When saving discovery results, merge new topics into the existing index. Do not overwrite previously tracked topics.

## Integration

- **Feeds into**: `yt-research` -- selected topics become research targets
- **Uses**: `channels/{channel_id}/config.json` for sources and scoring configuration
- **Pipeline**: `yt-topic` -> `yt-research` -> `yt-script` -> `yt-storyboard`

## Data Location

- Discovery results: `topics/{channel_id}/discoveries/{date}.json`
- Topic index: `topics/{channel_id}/index.json`
- Channel configs: `channels/{channel_id}/config.json`
