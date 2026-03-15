#!/bin/bash
# Auto-format and lint files on Write/Edit
# Triggered by Claude Code PostToolUse hook

set -e

# Read JSON input from stdin
INPUT=$(cat)

# Extract file_path from tool_input using jq
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Exit if no file path
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Exit if file doesn't exist
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Format and lint based on extension
case "$EXT" in
    ts|tsx|js|jsx)
        # TypeScript/JavaScript: prettier + eslint
        if command_exists prettier; then
            prettier --write "$FILE_PATH" 2>/dev/null || true
        fi
        if command_exists eslint; then
            eslint --fix "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    py)
        # Python: ruff format + ruff check
        if command_exists ruff; then
            ruff format "$FILE_PATH" 2>/dev/null || true
            ruff check --fix "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    go)
        # Go: gofmt + golangci-lint
        if command_exists gofmt; then
            gofmt -w "$FILE_PATH" 2>/dev/null || true
        fi
        if command_exists golangci-lint; then
            golangci-lint run --fix "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    json)
        # JSON: prettier
        if command_exists prettier; then
            prettier --write "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    md)
        # Markdown: prettier
        if command_exists prettier; then
            prettier --write "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    css|scss)
        # CSS/SCSS: prettier
        if command_exists prettier; then
            prettier --write "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
esac

exit 0
