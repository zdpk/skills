DOTCTL := python3 scripts/dotctl
SK := cargo run -q -p sk --

.PHONY: setup sync generate link skills plugins status help
.PHONY: global-skills-validate global-skills-list global-skills-dry-run global-skills-install global-skills-update
.PHONY: global-skills-install-codex global-skills-install-claude global-skills-install-antigravity global-skills-install-antigravity-ide global-skills-install-agents
.PHONY: sk-build sk-test sk-install sk-list sk-status sk-validate

setup:       ## Initial setup: create .env then full sync
	@test -f .env || (cp dotfiles/.env.example .env && echo "Created .env — fill in values then re-run make setup" && exit 1)
	@grep -q '=$$' .env && echo "Error: .env has empty values — fill them in first" && exit 1 || true
	$(DOTCTL) sync
	@echo ""
	@echo "Add to your shell profile:"
	@echo "  echo 'source $(CURDIR)/.env' >> ~/.zshrc"

sync:        ## Full sync: MCP + dotfiles + skills + plugins
	$(DOTCTL) sync

generate:    ## Regenerate MCP configs from .env
	$(DOTCTL) generate

link:        ## Create dotfile symlinks
	$(DOTCTL) link

skills:      ## Sync custom skills to Claude/Codex/OpenCode
	$(DOTCTL) skills

global-skills-validate: ## Validate root skills/
	python3 scripts/validate-skills.py

global-skills-list: ## List root skills/
	./scripts/install.sh list

global-skills-dry-run: ## Preview global skill symlinks
	./scripts/install.sh --dry-run --all

global-skills-install: ## Install root skills into Codex/Claude/Antigravity
	./scripts/install.sh --apply --all

global-skills-update: ## Refresh root skill symlinks
	./scripts/install.sh --apply --all

global-skills-install-codex: ## Install root skills into Codex
	./scripts/install.sh --apply --codex

global-skills-install-claude: ## Install root skills into Claude
	./scripts/install.sh --apply --claude

global-skills-install-antigravity: ## Install root skills into Antigravity
	./scripts/install.sh --apply --antigravity

global-skills-install-antigravity-ide: ## Install root skills into Antigravity IDE
	./scripts/install.sh --apply --antigravity-ide

global-skills-install-agents: ## Install root skills into ~/.agents/skills
	./scripts/install.sh --apply --agents

sk-build: ## Build the Rust root skill manager
	cargo build -p sk

sk-test: ## Test the Rust root skill manager
	cargo test -p sk

sk-install: ## Install sk into Cargo bin
	cargo install --path crates/sk --force

sk-list: ## List root skills with sk
	$(SK) list

sk-status: ## Show root skill install status with sk
	$(SK) status

sk-validate: ## Validate root skills with sk
	$(SK) validate

plugins:     ## Install Claude plugins from manifest
	$(DOTCTL) plugins

status:      ## Show current state
	$(DOTCTL) status

help:        ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  make %-34s %s\n", $$1, $$2}'
