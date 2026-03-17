# skills

AI agent skill registry & dotfiles. 87 skills across Claude Code, Codex, OpenCode — managed by a single CLI.

## Quick Install

```bash
curl -fsSL https://github.com/zdpk/skills/releases/latest/download/install.sh | bash
```

Or manually:

```bash
git clone git@github.com:zdpk/skills.git ~/.skills
cd ~/.skills/dotfiles
make setup
```

## What's Inside

```
dotfiles/
├── bin/sc                 # CLI — skill registry manager
├── skills/
│   ├── registry.yaml      # Single source of truth (87 skills)
│   └── custom/            # Custom skill files (42 SKILL.md)
│       ├── openspec/      #   spec-driven dev (11)
│       ├── maple/         #   MapleStory BGM (6)
│       ├── youtube/       #   YouTube content (4)
│       ├── threads/       #   Threads SNS (8)
│       ├── imagegen/      #   image generation (2)
│       ├── social/        #   X/Twitter (1)
│       ├── util/          #   utilities (3)
│       ├── project/       #   project-specific (2)
│       └── meta/          #   skill management (5)
├── claude/                # Claude Code config (CLAUDE.md, settings.json)
├── codex/                 # Codex config (automations, prompts, rules)
├── hooks/                 # Pre/post hooks (format, notify, session-start)
├── mcp-servers.json       # MCP server definitions
└── Makefile               # Convenience targets
```

## Install

### Option 1: install.sh (Recommended)

```bash
# Install to ~/.skills (default)
curl -fsSL https://github.com/zdpk/skills/releases/latest/download/install.sh | bash

# Custom install path
curl -fsSL https://github.com/zdpk/skills/releases/latest/download/install.sh | INSTALL_DIR=~/my-skills bash
```

`install.sh` does the following:

1. Clone repo to `~/.skills`
2. Symlink `bin/sc` to `~/.local/bin/sc` (or `~/bin/sc`)
3. Run `sc install` to download community skills to `~/.agents/skills/`
4. Print next steps

### Option 2: Git Clone

```bash
git clone git@github.com:zdpk/skills.git ~/.skills
cd ~/.skills/dotfiles

# Add sc to PATH (pick one)
ln -s $(pwd)/bin/sc ~/.local/bin/sc      # Linux/macOS
echo 'export PATH="$HOME/.skills/dotfiles/bin:$PATH"' >> ~/.zshrc  # or ~/.bashrc

# Install downloaded skills
sc install

# Verify
sc verify
sc list
```

### Option 3: Multi-VM Bootstrap

On a new machine after `git clone`:

```bash
cd ~/.skills/dotfiles

# 1. Install community skills
sc install

# 2. Check what's missing
sc diff

# 3. Deploy to a project
sc deploy dev --target ~/my-project
```

## Usage

### Browse Skills

```bash
sc list                          # All skills (table)
sc list --source custom          # Custom only
sc list --tag dev                # Dev-tagged only
sc list --agent codex            # Codex-compatible only
sc list --format json            # JSON output
sc info openspec                 # Detailed info for one skill
```

### Deploy Skills to a Project

```bash
# Deploy by profile (predefined tag sets)
sc deploy dev --target ~/my-project          # dev skills → .claude/skills/
sc deploy maple --target ~/bgm-project       # maple skills
sc deploy marketing --target ~/campaign       # marketing skills
sc deploy full --target ~/everything          # all skills

# Deploy by tags directly
sc deploy --tags dev,openspec --target ~/proj

# Preview before deploying
sc deploy dev --target ~/proj --dry-run

# Clean up old symlinks
sc deploy dev --target ~/proj --clean

# Deploy to Codex project
sc deploy dev --target ~/proj --agent codex   # → .codex/skills/
```

**Profiles:**

| Profile | Tags | Use case |
|---------|------|----------|
| `dev` | dev, openspec, util, meta | General development |
| `marketing` | content, social, marketing | Content/SNS |
| `maple` | maple, content, imagegen, youtube | MapleStory BGM |
| `youtube` | youtube, content, imagegen | YouTube production |
| `threads` | social, content, marketing | Threads automation |
| `full` | * (all) | Everything |

### Manage Skills (CRUD)

```bash
# Add a new skill
sc add my-new-skill \
  --source custom \
  --agent claude \
  --tags dev,util \
  --description "What this skill does"
# → Creates skills/custom/dev/my-new-skill/SKILL.md
# → Registers in registry.yaml

# Update metadata
sc update openspec --add-tags marketing
sc update openspec --remove-tags util
sc update openspec --set-tags dev,spec      # replace all tags
sc update openspec --description "New desc"

# Remove
sc remove old-skill                         # registry only
sc remove old-skill --delete-files          # + delete SKILL.md
sc remove old-skill --delete-files --force  # skip confirmation
```

### Import External Skills

```bash
# Import from another project's .claude/skills/
sc import ~/other-project/.claude/skills/cool-skill --tags dev

# Import from Codex skills (auto-detects agent)
sc import ~/.codex/skills/some-skill --tags dev --category util

# Custom name and category
sc import ~/path/to/skill --name my-name --category util --tags dev
```

### Multi-VM Sync

```bash
# VM-A: add skill, push
sc add new-tool --source custom --agent claude --tags dev
git add -A && git commit -m "add new-tool" && git push

# VM-B: pull, install, deploy
git pull
sc install          # reinstall downloaded skills
sc diff             # verify everything matches
sc deploy dev --target ~/project
```

### Health Check

```bash
sc verify           # Validate registry consistency
sc diff             # Compare registry vs filesystem
sc scan             # Find unregistered skills
sc scan --register  # Auto-register found skills
```

## install.sh

The release installer script for GitHub Releases:

```bash
#!/bin/bash
set -euo pipefail

REPO="zdpk/skills"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.skills}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

echo "Installing skills to $INSTALL_DIR..."

# Clone
if [ -d "$INSTALL_DIR" ]; then
  echo "Updating existing installation..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  git clone "https://github.com/$REPO.git" "$INSTALL_DIR"
fi

# Symlink sc to PATH
mkdir -p "$BIN_DIR"
ln -sf "$INSTALL_DIR/dotfiles/bin/sc" "$BIN_DIR/sc"
chmod +x "$INSTALL_DIR/dotfiles/bin/sc"

# Install downloaded skills
cd "$INSTALL_DIR/dotfiles"
bin/sc install 2>/dev/null || true

echo ""
echo "Installed! Add to PATH if needed:"
echo "  export PATH=\"$BIN_DIR:\$PATH\""
echo ""
echo "Quick start:"
echo "  sc list                              # browse skills"
echo "  sc deploy dev --target ~/my-project  # deploy to project"
echo "  sc diff                              # check status"
```

## Registry Schema

`skills/registry.yaml` is the single source of truth.

```yaml
version: 1

profiles:
  dev:
    description: "General development"
    tags: [dev, openspec, util, meta]

skills:
  - name: openspec                    # unique identifier
    source: custom                    # custom | downloaded | builtin
    agent: universal                  # claude | codex | gemini | opencode | universal
    tags: [dev, openspec]             # for profile matching
    path: skills/custom/openspec/openspec  # relative to repo root (or ~/ for external)
    description: "Spec-driven development CLI"
    # Optional fields (v1.1):
    install_source: "github:org/repo/path"  # for `sc install`
    import_origin: "/original/path"         # tracking for `sc import`
    created_at: "2026-03-17T12:00:00Z"
    updated_at: "2026-03-17T13:00:00Z"
    disabled: true                          # skip in deploy/list
```

**Source types:**

| Source | Description | Managed by |
|--------|------------|------------|
| `custom` | Hand-written, stored in this repo | You |
| `downloaded` | Community skills from marketplace | `sc install` |
| `builtin` | System skills (reference only) | Agent runtime |

## Makefile Targets

```bash
make skills-list                                    # sc list
make skills-info NAME=openspec                      # sc info
make skills-verify                                  # sc verify
make skills-diff                                    # sc diff
make skills-scan                                    # sc scan
make skills-deploy PROFILE=dev TARGET=~/project     # sc deploy
make skills-add NAME=x SOURCE=custom AGENT=claude TAGS=dev
make skills-remove NAME=x DELETE=1                  # with file deletion
make skills-update NAME=x ADD_TAGS=marketing
make skills-install                                 # sc install
make setup                                          # initial setup
```

## Creating a New Skill

```bash
# 1. Register (creates SKILL.md template)
sc add my-skill --source custom --agent claude --tags dev --description "My skill"

# 2. Edit the generated SKILL.md
$EDITOR skills/custom/dev/my-skill/SKILL.md

# 3. Deploy to test
sc deploy dev --target ~/test-project

# 4. Commit
git add -A && git commit -m "add my-skill"
```

## GitHub Release Setup

To enable `curl | bash` installation via GitHub Releases:

```bash
# 1. Create the install.sh (already in repo docs above)
# 2. Create a GitHub release
gh release create v1.0.0 --title "v1.0.0" --notes "Initial release"

# 3. Upload install.sh as release asset
gh release upload v1.0.0 install.sh

# 4. Users can now install with:
# curl -fsSL https://github.com/zdpk/skills/releases/latest/download/install.sh | bash
```

For automated releases, add `.github/workflows/release.yml`:

```yaml
name: Release
on:
  push:
    tags: ["v*"]
jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      - name: Create Release
        run: |
          gh release create ${{ github.ref_name }} \
            --title "${{ github.ref_name }}" \
            --generate-notes \
            install.sh
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## License

Private repository.
