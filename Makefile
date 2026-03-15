DOTCTL := python3 scripts/dotctl

.PHONY: sync generate link skills plugins status

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
