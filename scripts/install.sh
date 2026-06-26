#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_real="$(cd "$repo_root" && pwd -P)"
skills_dir="$repo_root/skills"
apply=false
list_only=false
targets=()

codex_dir="${CODEX_SKILLS_DIR:-${CODEX_HOME:-$HOME/.codex}/skills}"
claude_dir="${CLAUDE_SKILLS_DIR:-${CLAUDE_HOME:-$HOME/.claude}/skills}"
antigravity_dir="${ANTIGRAVITY_SKILLS_DIR:-$HOME/.gemini/antigravity/global_skills}"
antigravity_ide_dir="${ANTIGRAVITY_IDE_SKILLS_DIR:-$HOME/.gemini/antigravity-ide/global_skills}"
agents_dir="${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"

usage() {
  cat <<'USAGE'
Usage:
  scripts/install.sh list
  scripts/install.sh --dry-run --all
  scripts/install.sh --apply --all
  scripts/install.sh --apply --codex
  scripts/install.sh --apply --claude
  scripts/install.sh --apply --antigravity
  scripts/install.sh --apply --agents

Commands:
  list       List discovered local skills.
  install    Alias for --apply. Targets still required.
  update     Alias for --apply. Targets still required.

Options:
  --dry-run          Show planned symlinks without changing target directories.
  --apply            Create or refresh symlinks.
  --all              Target Codex, Claude, Antigravity, and Antigravity IDE.
  --codex            Target ~/.codex/skills.
  --claude           Target ~/.claude/skills.
  --antigravity      Target ~/.gemini/antigravity/global_skills.
  --antigravity-ide  Target ~/.gemini/antigravity-ide/global_skills.
  --agents           Target ~/.agents/skills.
  --both             Legacy alias for --agents --codex.
  -h, --help         Show this help.

Environment overrides:
  CODEX_SKILLS_DIR
  CLAUDE_SKILLS_DIR
  ANTIGRAVITY_SKILLS_DIR
  ANTIGRAVITY_IDE_SKILLS_DIR
  AGENTS_SKILLS_DIR
USAGE
}

add_target() {
  local name="$1"
  local dir="$2"
  targets+=("$name:$dir")
}

real_path() {
  python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    list)
      list_only=true
      ;;
    install|update)
      apply=true
      ;;
    --dry-run)
      apply=false
      ;;
    --apply)
      apply=true
      ;;
    --all)
      add_target "codex" "$codex_dir"
      add_target "claude" "$claude_dir"
      add_target "antigravity" "$antigravity_dir"
      add_target "antigravity-ide" "$antigravity_ide_dir"
      ;;
    --codex)
      add_target "codex" "$codex_dir"
      ;;
    --claude)
      add_target "claude" "$claude_dir"
      ;;
    --antigravity)
      add_target "antigravity" "$antigravity_dir"
      ;;
    --antigravity-ide)
      add_target "antigravity-ide" "$antigravity_ide_dir"
      ;;
    --agents)
      add_target "agents" "$agents_dir"
      ;;
    --both)
      add_target "agents" "$agents_dir"
      add_target "codex" "$codex_dir"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

python3 "$repo_root/scripts/validate-skills.py" "$skills_dir"

mapfile -t skill_paths < <(find "$skills_dir" -type f -name 'SKILL.md' -not -path '*/.*' -print | sed 's#/SKILL.md$##' | sort)

if [[ ${#skill_paths[@]} -eq 0 ]]; then
  echo "No skills to install."
  exit 0
fi

if [[ "$list_only" == true ]]; then
  for source_dir in "${skill_paths[@]}"; do
    echo "$(basename "$source_dir") $source_dir"
  done
  exit 0
fi

if [[ ${#targets[@]} -eq 0 ]]; then
  echo "Choose at least one target: --all, --codex, --claude, --antigravity, --agents, or --both." >&2
  usage >&2
  exit 1
fi

refresh_link() {
  local source_dir="$1"
  local target_name="$2"
  local target_root="$3"
  local skill_name
  local target_path
  local existing_target
  local existing_abs
  local existing_real
  local source_real

  skill_name="$(basename "$source_dir")"
  target_path="$target_root/$skill_name"
  source_real="$(real_path "$source_dir")"

  if [[ -L "$target_path" ]]; then
    existing_target="$(readlink "$target_path")"
    if [[ "$existing_target" = /* ]]; then
      existing_abs="$existing_target"
    else
      existing_abs="$(cd "$(dirname "$target_path")" && pwd)/$existing_target"
    fi
    existing_real="$(real_path "$existing_abs")"

    if [[ "$existing_target" == "$source_dir" || "$existing_real" == "$source_real" ]]; then
      echo "Already linked [$target_name]: $target_path -> $source_dir"
      return 0
    fi

    if [[ "$existing_target" == "$repo_root"/* || "$existing_target" == "$repo_real"/* || "$existing_real" == "$repo_real"/* ]]; then
      if [[ "$apply" == true ]]; then
        rm "$target_path"
        ln -s "$source_dir" "$target_path"
        echo "Updated link [$target_name]: $target_path -> $source_dir"
      else
        echo "Would update link [$target_name]: $target_path -> $source_dir"
      fi
      return 0
    fi

    echo "Refusing to replace external symlink [$target_name]: $target_path -> $existing_target" >&2
    return 1
  fi

  if [[ -e "$target_path" ]]; then
    echo "Refusing to overwrite existing path [$target_name]: $target_path" >&2
    return 1
  fi

  if [[ "$apply" == true ]]; then
    mkdir -p "$target_root"
    ln -s "$source_dir" "$target_path"
    echo "Linked [$target_name]: $target_path -> $source_dir"
  else
    echo "Would link [$target_name]: $target_path -> $source_dir"
  fi
}

for target in "${targets[@]}"; do
  target_name="${target%%:*}"
  target_root="${target#*:}"

  for source_dir in "${skill_paths[@]}"; do
    refresh_link "$source_dir" "$target_name" "$target_root"
  done
done
