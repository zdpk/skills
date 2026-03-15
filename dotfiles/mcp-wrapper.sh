#!/usr/bin/env bash
# MCP server wrapper — injects secrets from .env at runtime.
# Keeps config files secret-free for tools without native ${VAR} expansion.
#
# Config example:
#   "command": "/path/to/mcp-wrapper.sh",
#   "args": ["--env", "SERVER_VAR=$OUR_VAR", "--", "npx", "-y", "@server/pkg"]
#
# Flow:
#   1. Source .env (all vars become available)
#   2. Process --env flags (map SERVER_VAR to $OUR_VAR via indirect expansion)
#   3. Expand $VAR in remaining args via envsubst
#   4. exec the actual command

set -euo pipefail

DOTCTL_ENV="${DOTCTL_ENV:-$HOME/skills/.env}"

# 1. Source .env
if [[ -f "$DOTCTL_ENV" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$DOTCTL_ENV"
  set +a
fi

# 2. Parse --env flags: --env SERVER_VAR=$OUR_VAR
while [[ $# -gt 0 ]]; do
  case "$1" in
    --env)
      shift
      var_name="${1%%=*}"
      ref="${1#*=}"
      if [[ "$ref" == \$* ]]; then
        ref_name="${ref#\$}"
        export "$var_name"="${!ref_name:-}"
      else
        export "$var_name"="$ref"
      fi
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

# 3. Expand $VAR in remaining args
args=()
for arg in "$@"; do
  if [[ "$arg" == *'$'* ]] && command -v envsubst &>/dev/null; then
    args+=("$(envsubst <<< "$arg")")
  else
    args+=("$arg")
  fi
done

# 4. Exec
exec "${args[@]}"
