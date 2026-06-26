#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import shutil
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:  # pragma: no cover
    print("PyYAML is required: python3 -m pip install pyyaml", file=sys.stderr)
    raise SystemExit(2)


SLUG_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
ALLOWED_ROOT_FILES = {"registry.yaml", ".lock", ".gitkeep"}
DATASET_DIRS = ("index", "records", "raw", "runs", "tmp")


def now_iso() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def today() -> str:
    return datetime.now().astimezone().date().isoformat()


def expand_base(base: str | None) -> Path:
    raw = base or os.environ.get("DATA_STORE_ROOT") or "~/gdrive/.data"
    return Path(os.path.expanduser(raw)).resolve()


def display_base(base: str | None) -> str:
    return base or os.environ.get("DATA_STORE_ROOT") or "~/gdrive/.data"


def require_slug(kind: str, value: str) -> None:
    if not SLUG_RE.match(value):
        raise SystemExit(f"{kind} must be a lowercase hyphen slug: {value}")


def dataset_id(category: str, dataset: str) -> str:
    require_slug("category", category)
    require_slug("dataset", dataset)
    return f"{category}/{dataset}"


def dataset_path(base: Path, category: str, dataset: str) -> Path:
    return base / category / dataset


def load_yaml(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    return default if data is None else data


def atomic_write_yaml(path: Path, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            yaml.safe_dump(data, handle, allow_unicode=True, sort_keys=False)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp_name, path)
    except Exception:
        try:
            os.unlink(tmp_name)
        except FileNotFoundError:
            pass
        raise


def create_or_refresh_dataset(
    base: Path,
    base_display: str,
    category: str,
    dataset: str,
    owner_skill: str | None,
) -> Path:
    ds_id = dataset_id(category, dataset)
    ds_path = dataset_path(base, category, dataset)
    timestamp = now_iso()

    ds_path.mkdir(parents=True, exist_ok=True)
    for name in DATASET_DIRS:
        (ds_path / name).mkdir(exist_ok=True)

    dataset_yaml = ds_path / "dataset.yaml"
    if dataset_yaml.exists():
        dataset_doc = load_yaml(dataset_yaml, {})
        dataset_doc["updated"] = timestamp
        if owner_skill:
            dataset_doc["owner_skill"] = owner_skill
    else:
        dataset_doc = {
            "version": 1,
            "id": ds_id,
            "category": category,
            "dataset": dataset,
            "owner_skill": owner_skill,
            "created": timestamp,
            "updated": timestamp,
            "layout": {
                "records": "records",
                "raw": "raw",
                "index": "index",
                "runs": "runs",
                "tmp": "tmp",
            },
        }
    atomic_write_yaml(dataset_yaml, dataset_doc)

    state_yaml = ds_path / "state.yaml"
    if not state_yaml.exists():
        atomic_write_yaml(
            state_yaml,
            {
                "version": 1,
                "dataset_id": ds_id,
                "updated": timestamp,
                "latest_record_at": None,
                "latest_record_id": None,
                "cursor": None,
                "stats": {
                    "records": 0,
                    "raw": 0,
                },
            },
        )

    update_registry(base, base_display, category, dataset, owner_skill)
    return ds_path


def ensure_dataset(args: argparse.Namespace) -> None:
    base = expand_base(args.base)
    ds_path = create_or_refresh_dataset(
        base,
        display_base(args.base),
        args.category,
        args.dataset,
        args.owner_skill,
    )
    print(ds_path)


def update_registry(base: Path, base_display: str, category: str, dataset: str, owner_skill: str | None) -> None:
    registry_path = base / "registry.yaml"
    registry = load_yaml(
        registry_path,
        {
            "version": 1,
            "base_path": base_display,
            "updated": today(),
            "datasets": [],
        },
    )
    registry.setdefault("version", 1)
    registry["base_path"] = registry.get("base_path") or base_display
    registry["updated"] = today()
    registry.setdefault("datasets", [])

    ds_id = dataset_id(category, dataset)
    entry = {
        "id": ds_id,
        "category": category,
        "dataset": dataset,
        "owner_skill": owner_skill,
        "path": ds_id,
        "dataset_path": f"{ds_id}/dataset.yaml",
        "state_path": f"{ds_id}/state.yaml",
        "updated": today(),
    }

    replaced = False
    for index, existing in enumerate(registry["datasets"]):
        if existing.get("id") == ds_id:
            merged = {**existing, **{k: v for k, v in entry.items() if v is not None}}
            registry["datasets"][index] = merged
            replaced = True
            break
    if not replaced:
        registry["datasets"].append(entry)

    registry["datasets"] = sorted(registry["datasets"], key=lambda item: item.get("id", ""))
    atomic_write_yaml(registry_path, registry)


def resolve_dataset(args: argparse.Namespace) -> None:
    base = expand_base(args.base)
    print(dataset_path(base, args.category, args.dataset))


def safe_target_path(raw_target: str) -> Path:
    target = Path(raw_target)
    if target.is_absolute():
        raise SystemExit(f"target must be relative to the dataset: {raw_target}")
    if ".." in target.parts:
        raise SystemExit(f"target must not contain '..': {raw_target}")
    if not target.name:
        raise SystemExit(f"target must name a file: {raw_target}")
    return target


def import_file(args: argparse.Namespace) -> None:
    base = expand_base(args.base)
    ds_path = create_or_refresh_dataset(
        base,
        display_base(args.base),
        args.category,
        args.dataset,
        args.owner_skill,
    ).resolve()

    source = Path(os.path.expanduser(args.source)).resolve()
    if not source.is_file():
        raise SystemExit(f"source file does not exist: {source}")

    target_rel = safe_target_path(args.target or source.name)
    destination = (ds_path / target_rel).resolve()
    if os.path.commonpath([str(ds_path), str(destination)]) != str(ds_path):
        raise SystemExit(f"target escapes dataset path: {target_rel}")
    if source == destination:
        raise SystemExit(f"source and destination are the same file: {source}")
    if destination.exists() and not args.overwrite:
        raise SystemExit(f"destination exists; pass --overwrite to replace: {destination}")

    destination.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{destination.name}.", suffix=".tmp", dir=destination.parent)
    os.close(fd)
    try:
        shutil.copy2(source, tmp_name)
        os.replace(tmp_name, destination)
        if args.mode == "move":
            source.unlink()
    except Exception:
        try:
            os.unlink(tmp_name)
        except FileNotFoundError:
            pass
        raise

    print(destination)


def validate(args: argparse.Namespace) -> None:
    base = expand_base(args.base)
    errors: list[str] = []

    if not base.exists():
        errors.append(f"base path does not exist: {base}")
    elif not base.is_dir():
        errors.append(f"base path is not a directory: {base}")
    else:
        for child in base.iterdir():
            if child.is_file() and child.name not in ALLOWED_ROOT_FILES:
                errors.append(f"flat root file is not allowed: {child}")

    registry_path = base / "registry.yaml"
    registry = load_yaml(registry_path, None)
    if registry is None:
        errors.append(f"missing registry: {registry_path}")
    else:
        datasets = registry.get("datasets")
        if not isinstance(datasets, list):
            errors.append("registry.yaml datasets must be a list")
        else:
            for entry in datasets:
                if not isinstance(entry, dict):
                    errors.append("registry dataset entry must be a mapping")
                    continue
                category = entry.get("category")
                dataset = entry.get("dataset")
                if not category or not dataset:
                    errors.append(f"registry entry missing category or dataset: {entry}")
                    continue
                ds_id = dataset_id(category, dataset)
                if entry.get("id") != ds_id:
                    errors.append(f"registry id mismatch for {ds_id}: {entry.get('id')}")
                ds_path = dataset_path(base, category, dataset)
                if not ds_path.exists():
                    errors.append(f"dataset path missing: {ds_path}")
                    continue
                for required in ("dataset.yaml", "state.yaml"):
                    if not (ds_path / required).is_file():
                        errors.append(f"missing {required}: {ds_path}")
                for required in DATASET_DIRS:
                    if not (ds_path / required).is_dir():
                        errors.append(f"missing {required}/: {ds_path}")

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)

    print(f"Data store valid: {base}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Manage ~/gdrive/.data datasets for skills.")
    parser.add_argument("--base", help="Override data root. Defaults to DATA_STORE_ROOT or ~/gdrive/.data.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser("init", help="Create or refresh a dataset scaffold.")
    init_parser.add_argument("--category", required=True)
    init_parser.add_argument("--dataset", required=True)
    init_parser.add_argument("--owner-skill")
    init_parser.set_defaults(func=ensure_dataset)

    resolve_parser = subparsers.add_parser("resolve", help="Print the resolved dataset path.")
    resolve_parser.add_argument("--category", required=True)
    resolve_parser.add_argument("--dataset", required=True)
    resolve_parser.set_defaults(func=resolve_dataset)

    import_parser = subparsers.add_parser("import-file", help="Copy or move a file into a dataset.")
    import_parser.add_argument("--category", required=True)
    import_parser.add_argument("--dataset", required=True)
    import_parser.add_argument("--owner-skill")
    import_parser.add_argument("--source", required=True)
    import_parser.add_argument("--target", help="Relative target path inside the dataset. Defaults to source name.")
    import_parser.add_argument("--mode", choices=("copy", "move"), default="copy")
    import_parser.add_argument("--overwrite", action="store_true")
    import_parser.set_defaults(func=import_file)

    validate_parser = subparsers.add_parser("validate", help="Validate data root and registered datasets.")
    validate_parser.set_defaults(func=validate)
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
