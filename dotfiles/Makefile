.PHONY: skills-list skills-verify skills-deploy skills-scan skills-info \
       skills-add skills-remove skills-update skills-import skills-install skills-diff \
       setup

# ── Skills Registry — Read ───────────────────────────────────────────
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

# ── Skills Registry — CRUD ───────────────────────────────────────────
skills-add:
	@test -n "$(NAME)" || (echo "Usage: make skills-add NAME=my-skill SOURCE=custom AGENT=claude TAGS=dev" && exit 1)
	@test -n "$(SOURCE)" || (echo "Usage: make skills-add NAME=my-skill SOURCE=custom AGENT=claude TAGS=dev" && exit 1)
	@test -n "$(AGENT)" || (echo "Usage: make skills-add NAME=my-skill SOURCE=custom AGENT=claude TAGS=dev" && exit 1)
	@test -n "$(TAGS)" || (echo "Usage: make skills-add NAME=my-skill SOURCE=custom AGENT=claude TAGS=dev" && exit 1)
	@bin/skillsctl add $(NAME) --source $(SOURCE) --agent $(AGENT) --tags $(TAGS) $(if $(DESC),--description "$(DESC)")

skills-remove:
	@test -n "$(NAME)" || (echo "Usage: make skills-remove NAME=old-skill [DELETE=1]" && exit 1)
	@bin/skillsctl remove $(NAME) --force $(if $(DELETE),--delete-files)

skills-update:
	@test -n "$(NAME)" || (echo "Usage: make skills-update NAME=my-skill [ADD_TAGS=x,y] [REMOVE_TAGS=z] [SET_TAGS=a,b]" && exit 1)
	@bin/skillsctl update $(NAME) $(if $(ADD_TAGS),--add-tags $(ADD_TAGS)) $(if $(REMOVE_TAGS),--remove-tags $(REMOVE_TAGS)) $(if $(SET_TAGS),--set-tags $(SET_TAGS)) $(if $(AGENT),--agent $(AGENT)) $(if $(DESC),--description "$(DESC)")

# ── Skills Registry — Multi-VM ───────────────────────────────────────
skills-import:
	@test -n "$(PATH)" || (echo "Usage: make skills-import PATH=~/other/.claude/skills/cool-skill TAGS=dev" && exit 1)
	@test -n "$(TAGS)" || (echo "Usage: make skills-import PATH=~/other/.claude/skills/cool-skill TAGS=dev" && exit 1)
	@bin/skillsctl import $(PATH) --tags $(TAGS) $(if $(CATEGORY),--category $(CATEGORY)) $(if $(NAME),--name $(NAME))

skills-install:
	@bin/skillsctl install $(if $(FORCE),--force) $(if $(ONLY),--only $(ONLY))

skills-diff:
	@bin/skillsctl diff

# ── Setup ─────────────────────────────────────────────────────────────
setup:
	@echo "Setting up dotfiles..."
	@test -d ~/.claude || mkdir -p ~/.claude
	@echo "Done."
