# skills

Dotfiles and skills for AI coding tools: Claude Code, Codex, OpenCode, Gemini CLI, Claude Desktop, Antigravity.

## Setup (new machine)

```bash
git clone git@github.com:zdpk/skills.git ~/skills
cd ~/skills
make setup        # creates .env, runs full sync
echo "source ~/skills/.env" >> ~/.zshrc
```

## Commands

```
make setup        Initial setup: create .env then full sync
make sync         Full sync: MCP + dotfiles + skills + plugins
make generate     Regenerate MCP configs from .env
make link         Create dotfile symlinks
make skills       Sync custom skills to Claude/Codex/OpenCode
make plugins      Install Claude plugins from manifest
make status       Show current state
```

## What gets synced

| Category | Target | Method |
|----------|--------|--------|
| MCP servers | 6 tools | generated from `dotfiles/mcp-servers.json` |
| Dotfiles | `~/.claude/` | symlinked (settings, hooks, statusline) |
| Custom skills | Claude/Codex/OpenCode | symlinked from `dotfiles/skills/custom/` |
| Codex extras | `~/.codex/` | symlinked (prompts, automations, rules) |
| Plugins | Claude | installed from manifest |

## Custom skills

Organized by category under `dotfiles/skills/custom/`:

| Category | Skills | Description |
|----------|--------|-------------|
| **maple** | idea, maple-background, maple-character, maple-cover, maple-style, suno-prompt | MapleStory BGM content pipeline |
| **youtube** | yt-research, yt-script, yt-storyboard | YouTube production workflow |
| **openspec** | openspec + 10 workflow skills | Spec-driven development |
| **social** | x-research | X/Twitter research |
| **project** | manual-authoring, manual-sync | Project-specific (SNPortal) |
| **util** | flow-ingredients-sync, switch-google-account, re | General utilities |

Skills are symlinked flat into each tool (`~/.claude/skills/<name>`, etc.) — categories are repo-only organization.

## Community skills

Listed in `dotfiles/skills/manifests/community-skills.yaml`. Not stored in this repo — install via each tool's skill installer.

## MCP secret handling

| Tool | Secrets in config? | Method |
|------|:---:|--------|
| Claude Code | No | `${VAR}` native expansion |
| Gemini CLI | No | `$VAR` native expansion |
| Claude Desktop | No | `mcp-wrapper.sh` runtime injection |
| Codex | No | `mcp-wrapper.sh` runtime injection |
| OpenCode | No | `mcp-wrapper.sh` runtime injection |
| Antigravity | No | `mcp-wrapper.sh` runtime injection |

Exception: HTTP MCP servers (e.g. stitch) need literal secrets in Desktop/Codex/Antigravity/OpenCode configs.

## Project-level skills (skillsctl)

For installing skills into specific projects (not user-global):

```bash
./scripts/skillsctl sync --project /path/to/project --pack .claude/packs/install/default.yaml
```
