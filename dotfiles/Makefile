.PHONY: skills-list skills-verify skills-deploy skills-scan skills-info setup

# ── Skills Registry ───────────────────────────────────────────────────
skills-list:
	@bin/skillsctl list

skills-verify:
	@bin/skillsctl verify

skills-deploy:
	@test -n "$(PROFILE)" || (echo "Usage: make skills-deploy PROFILE=dev TARGET=~/my-project" && exit 1)
	@test -n "$(TARGET)" || (echo "Usage: make skills-deploy PROFILE=dev TARGET=~/my-project" && exit 1)
	@bin/skillsctl deploy $(PROFILE) --target $(TARGET)

skills-scan:
	@bin/skillsctl scan

skills-info:
	@test -n "$(NAME)" || (echo "Usage: make skills-info NAME=openspec" && exit 1)
	@bin/skillsctl info $(NAME)

# ── Setup ─────────────────────────────────────────────────────────────
setup:
	@echo "Setting up dotfiles..."
	@test -d ~/.claude || mkdir -p ~/.claude
	@echo "Done."
