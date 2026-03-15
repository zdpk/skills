---
name: imagegen-chatgpt
description: Generate images using ChatGPT (GPT-4o image generation) with optional reference image upload. Automates browser to upload references, enter prompts, and download results. Triggers on "imagegen-chatgpt", "chatgpt image", "gpt image", "이미지 생성 chatgpt".
argument-hint: --prompt "description" [--ref path] [--output dir]
---

# Image Generation — ChatGPT

Generate images via ChatGPT's browser UI (GPT-4o image generation) with optional reference images.

## Input Parsing

```
/imagegen-chatgpt --prompt "a pixel art forest scene" --ref ./reference.png --output ./output
```

| Param | Required | Default | Description |
|-------|:--------:|---------|-------------|
| `--prompt` | yes | — | Image generation prompt |
| `--ref` | no | — | Reference image path(s). Repeat for multiple |
| `--output` | no | `$PWD/output/imagegen/YYYY-MM-DD/` | Output directory |

## Output

- File saved to: `<output>/<prompt-slug>-001.png`
- If file exists, increments: `-002.png`, `-003.png`
- Prompt slug: first 5 words, lowercased, hyphened

## Workflow

### 1. Prepare output directory

```bash
mkdir -p <output_dir>
```

### 2. Open ChatGPT

```
tabs_context_mcp → find existing ChatGPT tab or create new
navigate → https://chatgpt.com/
wait 3 seconds
screenshot → verify ChatGPT loaded
```

### 3. Upload reference images (if --ref provided)

Click the attachment button (📎 or + icon) in the message input area, then upload via file input:

```javascript
(async () => {
  const fileInput = document.querySelector('input[type="file"]');
  if (!fileInput) {
    // Click attach button to reveal file input
    const attachBtn = document.querySelector('[aria-label*="Attach"]') ||
                      document.querySelector('button[aria-label*="upload"]');
    if (attachBtn) attachBtn.click();
    await new Promise(r => setTimeout(r, 500));
  }
  const input = document.querySelector('input[type="file"]');
  const response = await fetch('<DATA_URI_OR_URL>');
  const blob = await response.blob();
  const file = new File([blob], 'ref.png', { type: 'image/png' });
  const dt = new DataTransfer();
  dt.items.add(file);
  input.files = dt.files;
  input.dispatchEvent(new Event('change', { bubbles: true }));
  return 'Uploaded: ' + file.name;
})();
```

**For local files**: Use `mcp__claude-in-chrome__upload_image` tool to upload the reference image.

Wait for thumbnail to appear:
```
wait 2 seconds
screenshot → verify image thumbnail attached
```

Repeat for each `--ref` image.

### 4. Enter prompt and submit

If reference images were uploaded, prefix the prompt to instruct image generation:

**With reference:**
```
Generate an image based on the attached reference. <user prompt>
```

**Without reference:**
```
Generate an image: <user prompt>
```

```
left_click → message input textarea
type → <constructed prompt>
screenshot → verify prompt entered
left_click → send button (↑ arrow)
```

### 5. Wait for generation

ChatGPT generates images inline in the conversation. Typically 15-60 seconds.

```
wait 15 seconds
screenshot → check if image appeared
# repeat until image is visible in the response
```

Look for an `<img>` element in the latest assistant message, or a "View image" / canvas element.

### 6. Download result

ChatGPT renders generated images inline. Download via:

**Method A: Right-click save (if image is directly in DOM)**

Find the generated image element and extract its URL:

```javascript
(async () => {
  // Find the latest generated image in the conversation
  const images = document.querySelectorAll('img[alt*="Generated"], img[src*="oaidalleapi"], img[src*="files.oaiusercontent"]');
  const img = images[images.length - 1];
  if (!img) return 'No generated image found';

  const response = await fetch(img.src);
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

**Method B: Download button**

ChatGPT may show a download button (⬇) on hover over the generated image:

```
hover → generated image
find → download button
left_click → download
```

### 7. Save and report

Move downloaded file to output directory with prompt-based name.

Report:
- File path
- Prompt used
- Reference images used (if any)

## Tips

- ChatGPT excels at understanding complex scene descriptions in natural language
- Korean prompts work well (unlike Flow where English is preferred)
- For style replication, explicitly describe the style in the prompt alongside the reference
- If generation fails or produces text-only response, retry with "이미지로 생성해줘" appended
- ChatGPT may refuse certain prompts — rephrase if blocked
