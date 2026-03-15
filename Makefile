DOTCTL := python3 scripts/dotctl

.PHONY: setup sync generate link skills plugins status

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

plugins:     ## Install Claude plugins from manifest
	$(DOTCTL) plugins

status:      ## Show current state
	$(DOTCTL) status

help:        ## Show this help
	@grep -E '^[a-z]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  make %-12s %s\n", $$1, $$2}'
