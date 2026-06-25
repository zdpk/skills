---
name: ko-ja
description: Korean-to-Japanese natural translation for Korean learners, formerly jp-kj. Use when the user enters Korean and asks for 일본어로, 일본어 번역, 자연스러운 일본어, Korean to Japanese, SNS/Threads/bio/post Japanese wording, or study-oriented Korean-to-Japanese output. Translate Korean naturally into Japanese, then apply the shared ja-core workflow for a furigana section that includes full hiragana reading, word-level analysis, individual kanji character readings and meanings, sentence tracking, translation-pair tracking, word dates, and word frequency saving.
---

# KO JA

Respond in Korean by default.

This skill handles Korean to Japanese.
For the shared Japanese sentence processing and saving rules, read and apply:

```text
/Users/x/.agents/skills/ja-core/SKILL.md
```

## Workflow

1. Preserve the Korean original.
2. Translate it into natural Japanese.
3. Apply `ja-core` to the Japanese sentence.
4. Save the Korean source and Japanese result through `translation_pairs[]`.

## Output

Use this structure:

1. 한국어 원문
2. 자연스러운 일본어
3. 후리가나형
4. 한국어 역번역
5. 단어 분석
6. 개별 한자 분석
7. 뉘앙스/대안
8. 저장 기록

## Translation Rules

- Prefer natural Japanese over literal translation.
- Preserve requested tone, character voice, politeness, and platform context.
- If context is missing, default to neutral polite Japanese.
- For public-facing text, make the Japanese publishable first.
- If a meaningful alternative exists, show the best version first and one compact alternative after.

## Save Rules

Use `ja-core` save rules.

Pass these values into the core workflow:

- Korean source text
- Japanese sentence
- furigana
- full hiragana reading for storage field `reading`
- Korean back-translation
- tone/context
- source path when a learn file is involved

## Example

Input:

```text
일본어 공부하는 게 좋아요.
```

Output shape:

```text
1. 한국어 원문
일본어 공부하는 게 좋아요.

2. 자연스러운 일본어
日本語を勉強するのが好きです。

3. 후리가나형
- 문장: 日本語(にほんご)を勉強(べんきょう)するのが好(す)きです。
- 전체 읽기: にほんごをべんきょうするのがすきです

4. 한국어 역번역
일본어를 공부하는 것을 좋아합니다.
```
