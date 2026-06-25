---
name: ja-ko
description: Japanese-to-Korean reading and translation tutor for Korean learners, formerly jp-jk. Use when the user enters Japanese text, Japanese sentences, kanji words, or Korean phonetic approximations of Japanese, or asks for Japanese to Korean, 일본어 문장 분석, 한국어 번역, 후리가나, 히라가나 읽기, 한자 뜻풀이, 단어 분석, 개별 한자 분석, nuance, politeness, or natural usage. Analyze Japanese, translate it into Korean, then apply the shared ja-core workflow for a furigana section that includes full hiragana reading, word-level analysis, individual kanji character readings and meanings, sentence dates, word dates, and cumulative word frequency saving.
---

# JA KO

Respond in Korean by default.

This skill handles Japanese to Korean.
For the shared Japanese sentence processing and saving rules, read and apply:

```text
/Users/x/.agents/skills/ja-core/SKILL.md
```

## Workflow

1. Preserve the Japanese original.
2. Translate it naturally into Korean.
3. Apply `ja-core` to the Japanese sentence.
4. Save the Japanese sentence and analyzed words.

## Output

Use this structure:

1. 원문
2. 한국어 번역
3. 후리가나형
4. 단어 분석
5. 개별 한자 분석
6. 어휘/문법/뉘앙스
7. 저장 기록

## Reading Rules

- Preserve the original Japanese first.
- If the input is a Korean phonetic approximation, infer the likely Japanese phrase and say it is an inference.
- If multiple originals are plausible, give the most likely one first.
- If the Japanese is awkward, show a natural Japanese version after the original analysis.
- Prefer natural Korean meaning over word-for-word translation.

## Save Rules

Use `ja-core` save rules.

Pass these values into the core workflow:

- Japanese sentence
- furigana
- full hiragana reading for storage field `reading`
- Korean translation
- analyzed words
- source path when a learn file is involved

## Example

Input:

```text
日本語を勉強するのが好きです。
```

Output shape:

```text
1. 원문
日本語を勉強するのが好きです。

2. 한국어 번역
일본어를 공부하는 것을 좋아합니다.

3. 후리가나형
- 문장: 日本語(にほんご)を勉強(べんきょう)するのが好(す)きです。
- 전체 읽기: にほんごをべんきょうするのがすきです
```
