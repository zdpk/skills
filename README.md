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
make global-skills-install
                  Symlink root `skills/` into Codex/Claude/Antigravity
make sk-status    Show root `skills/` install status through the Rust CLI
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

## Global language skills

Language skill sources live under `skills/lang/`.

They are installed as flat symlinks into each tool. The repo category is not part of the installed skill name.

Current names:

- `ja-core`: Japanese processing core
- `ja-ko`: Japanese to Korean
- `ko-ja`: Korean to Japanese

Naming rule:

- Direction skills use `<source>-<target>`
- Language core skills use `<language>-core`
- Language codes use ISO 639-1, such as `ko`, `ja`, `en`, `id`

Install or update:

```bash
make global-skills-install
make global-skills-update
```

Dry-run and list:

```bash
make global-skills-dry-run
make global-skills-list
```

Default targets:

- Codex: `~/.codex/skills`
- Claude: `~/.claude/skills`
- Antigravity: `~/.gemini/antigravity/global_skills`
- Antigravity IDE: `~/.gemini/antigravity-ide/global_skills`

Developer target:

- Agents: `~/.agents/skills`

The installer only refreshes symlinks that already point inside this repo. It refuses to overwrite external symlinks or real directories.

## Root skills CLI

`sk` is the Rust CLI for the root `skills/` tree.

```bash
make sk-build
make sk-test
make sk-install
sk list
sk status
sk validate
sk install --dry-run --all
sk version
sk bump ja-core patch
```

`sk` reads `skills/registry.toml` for skill versions. `SKILL.md` frontmatter stays limited to `name` and `description`.

`sk status` checks the standard global skill targets:

- Codex
- Claude
- Antigravity
- Antigravity IDE

Add `--target agents` when checking the developer `~/.agents/skills` target.

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
