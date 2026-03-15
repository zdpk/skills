# Suno v5 Prompt Engineering Guide

## Hard Constraints
- **Max 500 characters** total prompt length
- Instrumental only — always include "Instrumental" or "No vocals"
- English prompts perform best on Suno

## Prompt Structure (recommended order)

```
[genre/style], [instrumentation], [mood/atmosphere], [texture/effects], [scene hint], [constraints]
```

Each section should be comma-separated descriptors, not full sentences.

## Effective Patterns

### DO
- Front-load the most important descriptors (genre + instrumentation)
- Use specific instrument names: "felt piano", "Rhodes EP", "celesta", "glockenspiel"
- Include texture words: "vinyl crackle", "tape warmth", "lo-fi", "reverb-drenched"
- Add one scene/atmosphere phrase: "late-night study", "rainy afternoon", "moonlit forest"
- End with "Instrumental, no vocals" and "loop-friendly" if needed
- Use commas between descriptors, not periods or full sentences

### DON'T
- Don't write paragraphs or full sentences (wastes characters)
- Don't use "remix of uploaded audio" (Suno v5 handles references differently)
- Don't list what to avoid (positive framing only)
- Don't repeat the same concept in different words
- Don't exceed 500 characters

## Character Budget Strategy

Target ~400 chars to leave breathing room. Breakdown:
- Genre/style: ~50 chars
- Instrumentation: ~80 chars
- Mood/texture: ~80 chars
- Scene/atmosphere: ~60 chars
- MapleStory reference: ~60 chars
- Constraints: ~40 chars
- Buffer: ~130 chars

## Example Prompts

### Lofi (387 chars)
```
Lofi hip-hop instrumental, mellow Rhodes electric piano melody, dusty vinyl crackle, tape-saturated warmth, lazy boom-bap drums with subtle swing, low-pass filtered bass, cozy late-night study vibe, nostalgic game OST atmosphere inspired by MapleStory Henesys peaceful village, warm analog texture, 78 BPM, Dm, Instrumental, no vocals, loop-friendly
```

### Piano (312 chars)
```
Solo felt piano instrumental, expressive gentle melody, warm upright piano with soft pedal resonance, intimate room reverb, nostalgic game soundtrack feel inspired by MapleStory Ellinia enchanted forest, dreamy ethereal atmosphere, delicate dynamics, 90 BPM, Eb major, Instrumental, no vocals, loop-friendly
```

### Music Box (298 chars)
```
Music box instrumental, crystalline bell-tone melody, soft celestial pads, gentle glockenspiel accents, magical childhood wonder, inspired by MapleStory Ludibrium toy castle whimsical fantasy, cute cozy sparkle, light reverb shimmer, 85 BPM, F major, Instrumental, no vocals, loop-friendly
```

### Piano + Music Box (356 chars)
```
Music box and felt piano duet instrumental, music box carries sparkling melody, warm upright piano provides gentle chords and counter-melody, soft strings pad, nostalgic heartwarming atmosphere inspired by MapleStory Kerning City rainy night streets, bittersweet urban solitude, 80 BPM, Am, Instrumental, no vocals, loop-friendly
```
