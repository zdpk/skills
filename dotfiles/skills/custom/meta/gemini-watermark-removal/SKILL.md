---
name: gemini-watermark-removal
description: 'Remove the visible Gemini AI watermark (star/sparkle logo, usually bottom-right) from images using the `gemini-watermark` CLI (gemini-watermark-removal). Use when asked to "remove Gemini watermark", "워터마크 제거", or to batch-clean a folder of Gemini-generated images. Note: this cannot remove SynthID (invisible watermark).'
---

# gemini-watermark-removal

## Overview

Use the installed `gemini-watermark` CLI to detect and remove the *visible* Gemini watermark from an image or a directory of images.

## Preconditions

- Ensure the CLI exists: `command -v gemini-watermark`
- If missing, install via Rust: `cargo install gemini-watermark-removal`

## Workflow

1. Decide the scope:
   - Single image file: run with optional `-o` (defaults to `<stem>_cleaned.<ext>` next to the input).
   - Directory batch: `-o <output_dir>` is required.
2. Prefer auto-detection (default). Only use `--force` if explicitly requested or detection keeps skipping images that clearly have the watermark.
3. Run the command.
4. Verify output files exist and look correct (spot-check a couple of images).

## Commands

Single image (explicit output):

```bash
gemini-watermark /path/to/photo.jpg -o /path/to/photo_cleaned.jpg
```

Single image (default output name):

```bash
gemini-watermark /path/to/photo.jpg
# -> /path/to/photo_cleaned.jpg
```

Batch directory:

```bash
mkdir -p /path/to/output
gemini-watermark /path/to/input/ -o /path/to/output/
```

More aggressive detection (lower threshold means more images will be processed):

```bash
gemini-watermark /path/to/photo.jpg --threshold 0.15
```

Force removal (skip detection):

```bash
gemini-watermark /path/to/photo.jpg -o /path/to/photo_cleaned.jpg --force
```

Troubleshooting watermark size mismatch:

```bash
gemini-watermark /path/to/photo.jpg --force-small
gemini-watermark /path/to/photo.jpg --force-large
```

## Notes

- Supported formats are typically: JPEG/JPG, PNG, WebP, BMP.
- `--quiet` suppresses non-error output; `-v/--verbose` prints more details.
- Avoid overwriting the input unless the user explicitly wants in-place output.
