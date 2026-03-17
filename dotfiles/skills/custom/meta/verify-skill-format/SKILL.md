---
name: verify-skill-format
description: Verify SKILL.md files have valid frontmatter and consistent naming.
---

# verify-skill-format

## Scope

Validate skill modules under `.claude/skills/**`.

## Checks

1. Every skill directory has a `SKILL.md` file.
2. `SKILL.md` begins with YAML frontmatter delimited by `---`.
3. Frontmatter contains:
   - `name`
   - `description`
4. `name` matches the directory basename.
5. Skill names are unique.

## Suggested Commands

```bash
rg --files ".claude/skills" -g "SKILL.md"
```

## Output

- List of violations with file paths
- If safe, propose exact edits (frontmatter fixes, renames) to resolve issues

