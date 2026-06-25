#!/usr/bin/env python3
"""Validate local skill folders before publishing them globally."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


NAME_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
FORBIDDEN_SKILL_DOCS = {
    "README.md",
    "CHANGELOG.md",
    "INSTALL.md",
    "INSTALLATION_GUIDE.md",
    "QUICK_REFERENCE.md",
}


def parse_frontmatter(path: Path) -> tuple[dict[str, str], list[str]]:
    errors: list[str] = []
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    if not lines or lines[0].strip() != "---":
        return {}, ["missing YAML frontmatter"]

    end_index = None
    for index, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            end_index = index
            break

    if end_index is None:
        return {}, ["unterminated YAML frontmatter"]

    fields: dict[str, str] = {}
    for line_number, raw_line in enumerate(lines[1:end_index], start=2):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            errors.append(f"frontmatter line {line_number} is not key: value")
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip().strip("'\"")
        fields[key] = value

    return fields, errors


def validate_skill(skill_dir: Path) -> list[str]:
    errors: list[str] = []
    skill_file = skill_dir / "SKILL.md"

    if not skill_file.exists():
        return [f"{skill_dir}: missing SKILL.md"]

    if not skill_file.is_file():
        return [f"{skill_file}: not a file"]

    fields, frontmatter_errors = parse_frontmatter(skill_file)
    errors.extend(f"{skill_file}: {error}" for error in frontmatter_errors)

    allowed_fields = {"name", "description"}
    extra_fields = sorted(set(fields) - allowed_fields)
    if extra_fields:
        errors.append(f"{skill_file}: unsupported frontmatter fields: {', '.join(extra_fields)}")

    name = fields.get("name", "")
    description = fields.get("description", "")

    if not name:
        errors.append(f"{skill_file}: missing frontmatter name")
    elif not NAME_RE.match(name):
        errors.append(f"{skill_file}: name must use lowercase letters, numbers, and hyphens")
    elif name != skill_dir.name:
        errors.append(f"{skill_file}: name must match directory name {skill_dir.name!r}")

    if not description:
        errors.append(f"{skill_file}: missing frontmatter description")

    for doc_name in FORBIDDEN_SKILL_DOCS:
        if (skill_dir / doc_name).exists():
            errors.append(f"{skill_dir / doc_name}: keep operational docs at repository root")

    return errors


def discover_skill_dirs(skills_dir: Path) -> list[Path]:
    skill_files = sorted(
        path
        for path in skills_dir.rglob("SKILL.md")
        if all(not part.startswith(".") for part in path.relative_to(skills_dir).parts)
    )
    return [path.parent for path in skill_files]


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate skills under a source directory.")
    parser.add_argument(
        "skills_dir",
        nargs="?",
        default="skills",
        help="Directory containing skill folders. Defaults to ./skills.",
    )
    args = parser.parse_args()

    skills_dir = Path(args.skills_dir)
    if not skills_dir.exists():
        print(f"{skills_dir}: directory does not exist", file=sys.stderr)
        return 1

    skill_dirs = discover_skill_dirs(skills_dir)

    if not skill_dirs:
        print(f"No skills found under {skills_dir}.")
        return 0

    all_errors: list[str] = []
    names: dict[str, Path] = {}
    for skill_dir in skill_dirs:
        skill_errors = validate_skill(skill_dir)
        all_errors.extend(skill_errors)

        fields, _ = parse_frontmatter(skill_dir / "SKILL.md")
        name = fields.get("name")
        if name:
            if name in names:
                all_errors.append(f"{skill_dir / 'SKILL.md'}: duplicate skill name also used by {names[name]}")
            else:
                names[name] = skill_dir

    if all_errors:
        for error in all_errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"Validated {len(skill_dirs)} skill(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
