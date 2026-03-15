# Flow Quota & Models Reference

## Available Image Models (Flow → Create Image)

| Model | Tier | Resolution | Credits/gen |
|-------|------|------------|-------------|
| Imagen 4 | All | - | 0 |
| 🍌 Nano Banana | Free+ | ~1K (1024×1024) | 0 |
| 🍌 Nano Banana Pro | Pro+ | Up to 4K+ | 0 |

Image generation uses **0 AI credits** (credits are for video/Veo models only).
Instead, images have **separate daily generation limits**.

## Daily Image Generation Limits

| Plan | Daily Cap | Resolution | Monthly Price |
|------|-----------|------------|---------------|
| Free (no subscription) | 2-3 images/day | ~1K max, watermarked | $0 |
| Google AI Pro | ~100/day (실제 20-100) | Up to 4K+ | $19.99/mo |
| Google AI Ultra | ~1,000/day | Highest (>4K) | $24.99/mo |

### Important Caveats

- **Pro tier is variable**: During peak hours, actual cap can drop to 20-50 images due to dynamic load balancing
- **Failed generations count** against your daily quota
- **Daily reset**: Limits reset daily (approximately 00:00 local time)
- **No rollover**: Unused daily allowance doesn't carry over

## AI Credits (Video Only)

AI credits are separate from image generation and used only for Veo video models:

| Plan | Monthly Credits | Reset |
|------|----------------|-------|
| Free | 50 daily | Daily |
| Google AI Pro | 1,000/month | Monthly billing cycle |
| Google AI Ultra | 25,000/month | Monthly billing cycle |

Video credit costs per generation:
- Veo 2 Fast: 10 credits
- Veo 3.1 Fast: 20 credits
- Veo 2/3.1 Quality: 100 credits

### Top-up Credits (Pro/Ultra only)

| Price | Credits |
|-------|---------|
| $25 | 2,500 |
| $50 | 5,000 |
| $200 | 20,000 |

Top-up credits valid for 12 months from purchase.

## Best Practices for Quota Management

1. **Use Outputs per prompt = 2** (default) to get 2 variations per generation, counts as 1 generation toward daily limit
2. **Avoid failed generations**: Use clear, specific prompts; include good reference images as ingredients
3. **Batch similar work**: Generate all variations for one map/scene together before moving to the next
4. **Off-peak hours**: Generate during off-peak hours for more reliable access to full Pro quota
5. **Track usage**: No official API to check remaining daily quota — track manually or note when rate-limited

## Source

- [Google One AI Credits Help](https://support.google.com/googleone/answer/16287445)
