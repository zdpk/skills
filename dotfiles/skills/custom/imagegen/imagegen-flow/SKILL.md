---
name: imagegen-flow
description: Generate images using Google Flow (Nano Banana models) with optional reference image upload. Automates browser to upload references, enter prompts, and download results. Triggers on "imagegen-flow", "flow image", "nano banana", "이미지 생성 flow".
argument-hint: --prompt "description" [--ref path] [--model name] [--output dir]
---

# Image Generation — Google Flow

Generate images via Google Flow's browser UI with optional reference image ingredients. Supports all available Flow models.

## Input Parsing

```
/imagegen-flow --prompt "a cozy cafe interior" --ref ./reference.png --model "Nano Banana 2" --output ./output
```

| Param | Required | Default | Description |
|-------|:--------:|---------|-------------|
| `--prompt` | yes | — | Image generation prompt (English recommended) |
| `--ref` | no | — | Reference image path(s). Repeat for multiple: `--ref a.png --ref b.png` |
| `--model` | no | `Nano Banana 2` | Flow model name |
| `--output` | no | `$PWD/output/imagegen/YYYY-MM-DD/` | Output directory |

## Output

- File saved to: `<output>/<prompt-slug>-001.png`
- If file exists, increments: `-002.png`, `-003.png`
- Prompt slug: first 5 words, lowercased, hyphened (e.g., `a-cozy-cafe-interior-with`)

## Workflow

### 1. Prepare output directory

```bash
mkdir -p <output_dir>
```

### 2. Open Google Flow

```
tabs_context_mcp → find or create Flow tab
navigate → https://labs.google/fx/tools/flow
wait 3 seconds
```

If user has a project URL, use it directly:
```
https://labs.google/fx/tools/flow/project/<project-id>
```

### 3. Switch to Images mode

Click "Images" tab (top nav, next to "Videos").

```
find → "Images" tab
left_click → Images tab
screenshot → verify "Create Image" input visible
```

### 4. Select model

Verify the model badge in the input bar (e.g., "🍌 Nano Banana 2").

If wrong model:
```
left_click → settings icon (sliders, right side of input bar)
screenshot → settings panel
# Click model dropdown → select requested model
left_click → outside panel to close
```

Available models (as of 2026-03):
- 🍌 Nano Banana 2 (default)
- 🍌 Nano Banana Pro
- Imagen 3
- Imagen 4 Ultra
- Veo (video only)

### 5. Upload reference images (if --ref provided)

For each reference image, inject via JavaScript file input:

```javascript
(async () => {
  const response = await fetch('<IMAGE_URL_OR_DATA_URI>');
  const blob = await response.blob();
  const file = new File([blob], 'ref.png', { type: 'image/png' });
  const input = document.querySelector('input[type="file"]');
  const dt = new DataTransfer();
  dt.items.add(file);
  input.files = dt.files;
  input.dispatchEvent(new Event('change', { bubbles: true }));
  return 'Uploaded: ' + file.name + ' (' + file.size + ' bytes)';
})();
```

**For local files**: Use `upload_image` MCP tool to convert to data URI first, or use the `mcp__claude-in-chrome__upload_image` tool directly.

After upload, handle the crop dialog:
```
wait 2 seconds
find → "Crop and Save" button
left_click → "Crop and Save"
```

Repeat for each `--ref` image.

### 6. Enter prompt and submit

```
left_click → input text area ("Generate an image from text and ingredients")
type → <prompt>
screenshot → verify prompt entered
left_click → "→" submit button (bottom-right)
```

### 7. Wait for generation

Images generate with progress percentage (0% → 100%). Typically 10-30 seconds.

```
wait 10 seconds
screenshot → check progress
# repeat until images appear
```

**Note**: Page may redirect to gemini.google.com during generation. Navigate back to Flow URL after ~15 seconds.

### 8. Download result

Hover over generated image → click ⬇ download icon:

```
hover → generated image
left_click → ⬇ download icon
left_click → "Download 2K" (preferred)
```

If UI download fails, use JavaScript fallback:

```javascript
(async () => {
  const imgs = document.querySelectorAll('img');
  // Generated images start after UI elements (index 3+)
  const imgEl = imgs[3];
  const response = await fetch(imgEl.src);
  const blob = await response.blob();
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = '<prompt-slug>-001.png';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  return 'Downloaded: ' + blob.size + ' bytes';
})();
```

### 9. Save and report

Move downloaded file to output directory with prompt-based name.

Report:
- File path
- Model used
- Prompt used
- Reference images used (if any)

## Quota Management

If daily quota exhausted, use `/switch-google-account` to rotate Google accounts.

## Tips

- English prompts produce best results with Nano Banana models
- Nano Banana 2: best for stylized/artistic images
- Nano Banana Pro: best for reference-heavy style transfer
- Imagen 4 Ultra: best for photorealistic output
- Multiple reference images (2-3) improve style consistency
