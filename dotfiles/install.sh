#!/bin/bash
set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────
REPO="zdpk/skills"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.skills}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
DOTFILES_DIR="$INSTALL_DIR/dotfiles"
SKILLS_VERSION="${SKILLS_VERSION:-latest}"

# ── Colors ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}==>${NC} $*"; }
ok()    { echo -e "${GREEN}==>${NC} $*"; }
warn()  { echo -e "${YELLOW}==>${NC} $*"; }
error() { echo -e "${RED}==>${NC} $*" >&2; }

# ── Prerequisites ─────────────────────────────────────────────────────
check_deps() {
    local missing=()
    for cmd in git python3 curl; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        error "Missing required tools: ${missing[*]}"
        error "Install them first, then re-run this script."
        exit 1
    fi

    # Check Python has yaml
    if ! python3 -c "import yaml" 2>/dev/null; then
        warn "Python 'yaml' module not found. Installing PyYAML..."
        python3 -m pip install --user PyYAML 2>/dev/null || {
            error "Failed to install PyYAML. Run: pip install PyYAML"
            exit 1
        }
    fi
}

# ── Clone or Update ───────────────────────────────────────────────────
install_repo() {
    if [ -d "$INSTALL_DIR/.git" ]; then
        info "Updating existing installation at $INSTALL_DIR..."
        git -C "$INSTALL_DIR" pull --ff-only || {
            warn "Pull failed (diverged?). Skipping update."
        }
    else
        if [ -d "$INSTALL_DIR" ]; then
            error "$INSTALL_DIR exists but is not a git repo."
            error "Remove it first: rm -rf $INSTALL_DIR"
            exit 1
        fi
        info "Cloning $REPO to $INSTALL_DIR..."
        git clone "https://github.com/$REPO.git" "$INSTALL_DIR"
    fi
}

# ── sk binary ─────────────────────────────────────────────────────────
detect_sk_asset() {
    local os arch
    os="$(uname -s)"
    arch="$(uname -m)"

    case "$os:$arch" in
        Darwin:arm64|Darwin:aarch64)
            echo "sk-aarch64-apple-darwin"
            ;;
        Linux:x86_64|Linux:amd64)
            echo "sk-x86_64-unknown-linux-gnu"
            ;;
        *)
            return 1
            ;;
    esac
}

release_download_base() {
    if [ "$SKILLS_VERSION" = "latest" ]; then
        echo "https://github.com/$REPO/releases/latest/download"
    else
        echo "https://github.com/$REPO/releases/download/$SKILLS_VERSION"
    fi
}

install_prebuilt_sk() {
    local asset url binary tmp

    if ! command -v curl &>/dev/null; then
        warn "curl not found; cannot download prebuilt sk."
        return 1
    fi

    if ! asset="$(detect_sk_asset)"; then
        warn "No prebuilt sk asset for $(uname -s)/$(uname -m)."
        return 1
    fi

    binary="$INSTALL_DIR/target/release/sk"
    tmp="$binary.tmp"
    url="$(release_download_base)/$asset"

    info "Downloading prebuilt sk ($asset)..."
    mkdir -p "$(dirname "$binary")"
    if curl -fsSL -o "$tmp" "$url"; then
        mv "$tmp" "$binary"
        chmod +x "$binary"
        ok "Installed prebuilt sk -> $binary"
        return 0
    fi

    rm -f "$tmp"
    warn "Failed to download prebuilt sk from $url"
    return 1
}

# ── Symlink CLIs to PATH ─────────────────────────────────────────────
install_bin() {
    local sc_path="$DOTFILES_DIR/bin/sc"
    local sk_path="$DOTFILES_DIR/bin/sk"

    if [ ! -f "$sc_path" ]; then
        error "sc not found at $sc_path"
        exit 1
    fi

    chmod +x "$sc_path"
    mkdir -p "$BIN_DIR"
    ln -sf "$sc_path" "$BIN_DIR/sc"
    ok "Linked sc -> $BIN_DIR/sc"

    if [ -f "$sk_path" ]; then
        chmod +x "$sk_path"
        install_prebuilt_sk || exit 1
        ln -sf "$sk_path" "$BIN_DIR/sk"
        ok "Linked sk -> $BIN_DIR/sk"
    fi

    # Check if BIN_DIR is in PATH
    if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
        warn "$BIN_DIR is not in your PATH."
        echo ""
        echo "  Add this to your shell profile (~/.zshrc or ~/.bashrc):"
        echo ""
        echo "    export PATH=\"$BIN_DIR:\$PATH\""
        echo ""
    fi
}

# ── Install Downloaded Skills ─────────────────────────────────────────
install_skills() {
    info "Installing downloaded skills..."
    cd "$DOTFILES_DIR"
    bin/sc install 2>&1 | while IFS= read -r line; do
        echo "    $line"
    done
    ok "Skills installed."
}

# ── Setup Directories ─────────────────────────────────────────────────
setup_dirs() {
    mkdir -p ~/.claude 2>/dev/null || true
    mkdir -p ~/.agents/skills 2>/dev/null || true
}

# ── Summary ───────────────────────────────────────────────────────────
print_summary() {
    local total
    total=$(cd "$DOTFILES_DIR" && bin/sc list --format json 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ok "Installation complete!"
    echo ""
    echo "  Install dir:  $INSTALL_DIR"
    echo "  CLI:          $BIN_DIR/sc"
    echo "  Root CLI:     $BIN_DIR/sk"
    echo "  Skills:       $total registered"
    echo ""
    echo "  Quick start:"
    echo "    sc list                              # browse skills"
    echo "    sk status                            # inspect root skills"
    echo "    sc deploy dev --target ~/my-project  # deploy to project"
    echo "    sc diff                              # check status"
    echo "    sc --help                            # all commands"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# ── Main ──────────────────────────────────────────────────────────────
main() {
    echo ""
    echo "  skills installer"
    echo "  github.com/$REPO"
    echo ""

    check_deps
    install_repo
    setup_dirs
    install_bin
    install_skills
    print_summary
}

main "$@"
