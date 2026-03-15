---
name: switch-google-account
description: Switch the active Google account in Chrome browser via browser automation. Use when Google service quota is exhausted (e.g., Flow image generation daily limit), or when the user needs to switch to a different Google account. Triggers on "switch google account", "계정 전환", "구글 계정 변경", "switch account", "quota exhausted", or when a Google service reports rate limiting.
---

# Switch Google Account

Switch the active Google account in Chrome when quota is exhausted or a different account is needed.

## Input Parsing

```
/switch-google-account [target_email]
```

- **target_email**: Optional. Email to switch to. If omitted, rotate to next account in config.

## Account Config

Account list is stored in the **project root** (not in this skill):

```
./google_accounts.json
```

This file contains `current_active` and the `accounts` array. Update it after each switch.

## Workflow

### Step 1: Read Account Config

Read `./google_accounts.json` for available accounts and current active.

### Step 2: Determine Target

- If `target_email` given → use it
- If omitted → rotate to next account after `current_active`

### Step 3: Browser Automation

1. Navigate to `https://myaccount.google.com`
2. Click profile avatar (top-right corner)
3. Find and click target account in the account list
4. Wait for switch completion
5. Verify by checking displayed email/profile

```
navigate → myaccount.google.com
wait 2s → screenshot
find → profile avatar (top-right)
left_click → avatar
screenshot → verify account list appeared
find → target email text
left_click → target account row
wait 3s → screenshot → verify switch
```

### Step 4: Update Config

Update `current_active` in `./google_accounts.json`.

### Step 5: Return to Service

If switching mid-workflow (e.g., during maple-style generation), navigate back to the service URL (e.g., Flow project page).

## Output

- Previous active account
- New active account
- Service URL navigated back to (if applicable)
