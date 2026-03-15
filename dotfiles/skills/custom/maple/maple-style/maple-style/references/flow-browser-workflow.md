# Google Flow Browser Automation Workflow

## Prerequisites

- User must be logged into Google account with Gemini PRO subscription
- Chrome browser must be connected via Claude in Chrome extension
- Google Flow project URL (or create new at labs.google/fx/tools/flow)

## URL Pattern

```
https://labs.google/fx/tools/flow/project/<project-id>
```

User's default project ID: `6623e9db-6689-4e03-be38-9f7f75c0f06f`

## Step-by-Step Browser Automation

### 1. Get Tab Context

```
tabs_context_mcp → get available tabs
```

If no Flow tab exists, create a new tab and navigate.

### 2. Navigate to Flow

```
navigate → labs.google/fx/tools/flow/project/<project-id>
wait 3 seconds for page load
screenshot → verify page loaded
```

### 3. Switch to Images Mode

The page may default to "Videos" tab. Click "Images" tab (top-left, next to "Videos").

```
find → "Images" tab button
left_click → Images tab
screenshot → verify "Create Image" mode is active
```

Verify: Input area shows "Create Image" dropdown and "🍌 Nano Banana Pro" badge.

### 4. Configure Settings (if needed)

Click the settings icon (⚙️/sliders, right side of input bar) to adjust:

- **Aspect Ratio**: Landscape (16:9) | Portrait (9:16) | Square (1:1)
- **Outputs per prompt**: 1-4 (default: 2)
- **Model**: Must be "🍌 Nano Banana Pro"

```
left_click → settings icon (sliders icon, right of "x2")
screenshot → verify settings panel
# adjust as needed
left_click → outside panel to close
```

### 5. Add Ingredients (Reference Images)

Two methods available: select from existing gallery OR upload from URL programmatically.

#### Method A: Select from Existing Gallery by UUID

If the ingredient was previously uploaded and its UUID is tracked in `flow_uploaded_ingredients.json`:

```
left_click → "+" button
screenshot → ingredients panel with image grid
```

Then use JavaScript to click the exact ingredient by UUID:

```javascript
// Select ingredient by UUID (from flow_uploaded_ingredients.json → flow_uuid field)
document.querySelectorAll('button').forEach(btn => {
  if (getComputedStyle(btn).backgroundImage.includes('TARGET_UUID')) btn.click();
});
```

This is reliable regardless of gallery ordering — even if new ingredients were added manually outside this skill.

#### Method B: Upload from URL via JavaScript (Recommended)

Programmatically fetch an image from any URL and inject it into the hidden file input.
This works with maplestory.io API, wiki images, or any accessible image URL.

```javascript
javascript_tool → run this code:

(async () => {
  const response = await fetch('<IMAGE_URL>');
  const blob = await response.blob();
  const file = new File([blob], '<filename>.png', { type: 'image/png' });
  const input = document.querySelector('input[type="file"]');
  const dt = new DataTransfer();
  dt.items.add(file);
  input.files = dt.files;
  input.dispatchEvent(new Event('change', { bubbles: true }));
  return 'Uploaded: ' + file.name + ' (' + file.size + ' bytes)';
})();
```

After the script runs, a "Crop your ingredient" dialog appears:

```
wait 2 seconds
find → "Crop and Save" button
left_click → "Crop and Save"
# Image is added as ingredient
```

#### Capturing UUID After Upload

After "Crop and Save", the new ingredient gets a UUID. Capture it immediately:

```javascript
// Collect all current ingredient UUIDs from the gallery
const uuids = [];
document.querySelectorAll('button').forEach(btn => {
  const bg = getComputedStyle(btn).backgroundImage;
  const m = bg.match(/image\/([a-f0-9-]+)\?/);
  if (m) uuids.push(m[1]);
});
JSON.stringify(uuids);
```

Diff this list against previously known UUIDs (from `flow_uploaded_ingredients.json`) to identify the newly added UUID. Save it as `flow_uuid` in the tracking file.

#### UUID Technical Details

- Each ingredient is a `<button>` with CSS `background-image` URL containing the UUID
- URL pattern: `storage.googleapis.com/ai-sandbox-videofx/image/<UUID>`
- The grandparent `<div>` has `data-index` for display order (changes when items are reordered)
- **UUID is immutable** — it never changes regardless of gallery ordering or new uploads
- As of 2026-02-16, all ingredients render in DOM simultaneously (no lazy-load). Re-verify if count exceeds 100.

Repeat for multiple reference images. Each upload adds another ingredient thumbnail.

##### Useful MapleStory Image URLs

maplestory.io API map renders:
- Minimap: `https://maplestory.io/api/GMS/62/map/<MAP_ID>/miniMap`
- Full render: `https://maplestory.io/api/GMS/62/map/<MAP_ID>/render`
- Icon: `https://maplestory.io/api/GMS/62/map/<MAP_ID>/icon`

Common MAP_IDs:
- 100000000: Henesys
- 101000000: Ellinia
- 103000000: Kerning City
- 104000000: Lith Harbor
- 102000000: Perion
- 120000000: Nautilus
- 200000000: Orbis
- 211000000: El Nath
- 220000000: Ludibrium
- 230000000: Aquarium
- 240000000: Leafre

### 6. Type Prompt

Click on the text input area and type the style transfer prompt.

```
left_click → input text area ("Generate an image from text and ingredients")
type → <prompt text>
screenshot → verify prompt entered
```

### 7. Submit

```
left_click → "→" submit button (bottom-right)
```

### 8. Wait for Generation

Images generate with progress percentage shown (0% → 100%). Typically takes 10-30 seconds.

```
wait 10 seconds
screenshot → check progress
# repeat wait + screenshot until images appear (no more % indicator)
```

**Important**: The page may redirect to gemini.google.com during generation. If this happens, navigate back to the Flow project URL after ~15 seconds.

### 9. Download Generated Images

#### Method A: UI Download Button (Primary)

Hover over generated image → overlay icons appear → click ⬇ download icon.

```
hover → over generated image
# Overlay: ↩ (remix) | ♡ (favorite) | ⬇ (download) | ⋮ (more)
left_click → ⬇ download icon
# Dropdown appears: "Download 1K" | "Download 2K" | "Download 4K (Upgrade)"
left_click → "Download 1K" or "Download 2K"
```

Resolution options by plan:
- **Pro**: Download 1K, Download 2K
- **Ultra**: Download 1K, 2K, 4K

**Note**: The dropdown items have `role="menuitem"`. If coordinate clicks miss, use JS:

```javascript
document.querySelector('[role="menuitem"]').click(); // clicks first (1K) option
```

#### Method B: JavaScript Fetch Download (Fallback)

If UI download doesn't work (Chrome "ask where to save" dialog blocks automation):

```javascript
(async () => {
  // Find the generated image (index 3+ are generated, 0-2 are UI elements)
  const imgEl = document.querySelectorAll('img')[3];
  const response = await fetch(imgEl.src);
  const blob = await response.blob();
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'MapleStory_Generated.png';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
  return 'Downloaded: ' + blob.size + ' bytes';
})();
```

**Note**: This downloads the display-resolution image (~1K). For higher resolution, use the UI button.

#### Image URL Pattern

Generated images are stored at:
```
https://storage.googleapis.com/ai-sandbox-videofx/image/<uuid>
```

These URLs are accessible without authentication and can be fetched from the `img` elements on the page.

## Common Issues

### Page Redirects to Gemini
During or after generation, the tab may redirect to gemini.google.com. Navigate back to the Flow URL to see results.

### File Upload
Use the JavaScript fetch + file input method (Method B in Step 5). This bypasses the native file picker dialog which cannot be automated. The `upload_image` tool does NOT work reliably for this page — always use JavaScript injection.

### Model Verification
Always verify "🍌 Nano Banana Pro" is shown in the input bar. If a different model is shown, click settings and change the Model dropdown.
