# Design: skillsctl CRUD & Multi-VM Sync

## Architecture

```
bin/skillsctl (단일 Python 파일)
├── 기존 commands (list, deploy, verify, scan, info)
└── 신규 commands
    ├── add      ─→ RegistryWriter.add_skill()
    ├── remove   ─→ RegistryWriter.remove_skill()
    ├── update   ─→ RegistryWriter.update_skill()
    ├── import   ─→ SkillImporter.import_skill()
    ├── install  ─→ SkillInstaller.install_all()
    └── diff     ─→ SkillDiffer.compare()
```

## Core Components

### 1. RegistryWriter

registry.yaml의 원자적 읽기/쓰기를 담당.

```python
class RegistryWriter:
    """
    YAML round-trip을 직접 구현.
    PyYAML의 dump는 주석/순서를 보존하지 않으므로,
    skills 리스트만 조작하고 나머지(version, profiles)는 보존.
    """

    def load(self) -> dict
    def save(self, data: dict) -> None
    def add_skill(self, entry: dict) -> None
    def remove_skill(self, name: str) -> dict  # 제거된 entry 반환
    def update_skill(self, name: str, updates: dict) -> tuple[dict, dict]  # before, after
    def find_skill(self, name: str) -> dict | None
    def find_similar(self, name: str, threshold: int = 3) -> list[str]  # 유사 이름
```

**YAML Write 전략:**

PyYAML `dump()`를 사용하되, 필드 순서를 보장하기 위해 `OrderedDict` + custom representer 사용.

```python
import yaml
from collections import OrderedDict

FIELD_ORDER = [
    'name', 'source', 'agent', 'tags', 'path', 'description',
    'install_source', 'import_origin', 'created_at', 'updated_at'
]

def ordered_skill(entry: dict) -> OrderedDict:
    """필드를 정의된 순서로 정렬, 빈 값 생략"""
    return OrderedDict(
        (k, entry[k]) for k in FIELD_ORDER
        if k in entry and entry[k] is not None and entry[k] != ""
    )
```

### 2. SkillImporter

외부 경로의 스킬을 repo로 복사 + 등록.

```python
class SkillImporter:
    def import_skill(self, source_path, name, category, agent, tags) -> dict:
        # 1. source_path 검증 (SKILL.md 존재)
        # 2. target_dir = skills/custom/{category}/{name}/
        # 3. shutil.copytree(source_dir, target_dir)
        # 4. RegistryWriter.add_skill(entry)
        # 5. return created entry
```

### 3. SkillInstaller

downloaded 스킬 재설치.

```python
class SkillInstaller:
    def install_all(self, target_dir, only=None, force=False) -> dict:
        # 1. registry에서 source=downloaded 필터
        # 2. install_source 파싱
        # 3. 타입별 다운로드 (github/url/local)
        # 4. 결과 리포트 반환

    def _install_github(self, spec: str, target: Path) -> bool
    def _install_url(self, url: str, target: Path) -> bool
    def _install_local(self, path: str, target: Path) -> bool
```

GitHub 설치는 `gh api` CLI를 subprocess로 호출 (gh 인증 활용).

### 4. SkillDiffer

registry vs 파일시스템 비교.

```python
class SkillDiffer:
    def compare(self) -> list[DiffEntry]:
        # 1. registry 로드
        # 2. 각 스킬의 expected path 계산
        # 3. 파일시스템 존재 여부 확인
        # 4. 파일시스템 스캔으로 미등록 스킬 탐지
        # 5. DiffEntry(status, name, detail) 리스트 반환

@dataclass
class DiffEntry:
    status: str  # OK, MISSING, EXTRA, MOVED
    name: str
    detail: str
```

## CLI Argument Parsing

기존 `argparse` subparser 구조에 6개 command 추가:

```python
# add
p_add = sub.add_parser('add')
p_add.add_argument('name')
p_add.add_argument('--source', required=True, choices=VALID_SOURCES)
p_add.add_argument('--agent', required=True)
p_add.add_argument('--tags', required=True)
p_add.add_argument('--category')
p_add.add_argument('--description', default='')
p_add.add_argument('--path')
p_add.add_argument('--install-source')

# remove
p_rm = sub.add_parser('remove')
p_rm.add_argument('name')
p_rm.add_argument('--delete-files', action='store_true')
p_rm.add_argument('--force', action='store_true')

# update
p_up = sub.add_parser('update')
p_up.add_argument('name')
p_up.add_argument('--add-tags')
p_up.add_argument('--remove-tags')
p_up.add_argument('--set-tags')
p_up.add_argument('--agent')
p_up.add_argument('--source')
p_up.add_argument('--description')
p_up.add_argument('--path')

# import
p_imp = sub.add_parser('import')
p_imp.add_argument('path')
p_imp.add_argument('--name')
p_imp.add_argument('--category', default='imported')
p_imp.add_argument('--agent')
p_imp.add_argument('--tags', required=True)

# install
p_inst = sub.add_parser('install')
p_inst.add_argument('--target', default='~/.agents/skills/')
p_inst.add_argument('--only')
p_inst.add_argument('--skip-existing', action='store_true', default=True)
p_inst.add_argument('--force', action='store_true')

# diff
p_diff = sub.add_parser('diff')
p_diff.add_argument('--format', choices=['table', 'json'], default='table')
```

## Multi-VM Sync Flow

```
┌──────────────────────────────────────────────────────┐
│  VM-A (primary dev machine)                          │
│                                                      │
│  1. skillsctl add new-skill --source custom ...      │
│  2. git add && git commit && git push                │
└───────────────────────┬──────────────────────────────┘
                        │  git
                        ▼
┌──────────────────────────────────────────────────────┐
│  GitHub (dotfiles repo)                              │
│  - skills/registry.yaml (source of truth)            │
│  - skills/custom/**    (custom skill files)          │
│  - bin/skillsctl       (CLI)                         │
└───────────────────────┬──────────────────────────────┘
                        │  git
                        ▼
┌──────────────────────────────────────────────────────┐
│  VM-B (new machine / server)                         │
│                                                      │
│  1. git pull                                         │
│  2. skillsctl install        # downloaded 스킬 재설치 │
│  3. skillsctl deploy dev --target ~/project          │
│  4. skillsctl diff           # 상태 검증             │
└──────────────────────────────────────────────────────┘
```

## Edge Cases

### add 중복 이름
- 대소문자 무시 비교 (`OpenSpec` == `openspec`)
- 에러 + 기존 entry 정보 출력 + `--force`로 덮어쓰기 가능

### remove 후 deploy된 symlink
- `remove`는 registry만 수정, 이미 deploy된 symlink은 건드리지 않음
- `deploy --clean`을 별도로 실행해야 정리됨
- 경고 메시지 출력: "Note: deployed symlinks are not affected. Run `deploy --clean` to sync."

### import 시 부속 파일
- SKILL.md와 같은 디렉토리의 모든 파일을 복사
- `.git`, `__pycache__`, `node_modules` 제외

### install 시 gh 미설치
- `gh` 명령 존재 확인 후 없으면 에러 + 설치 안내

### YAML 병합 충돌
- skills 리스트를 name 기준 알파벳순으로 정렬하므로 충돌 최소화
- 충돌 발생 시 `skillsctl verify`로 검증 가능

## Makefile 추가 타겟

```makefile
skills-add:
	@bin/skillsctl add $(NAME) --source $(SOURCE) --agent $(AGENT) --tags $(TAGS)

skills-remove:
	@bin/skillsctl remove $(NAME) $(if $(DELETE),--delete-files)

skills-update:
	@bin/skillsctl update $(NAME) $(FLAGS)

skills-import:
	@bin/skillsctl import $(PATH) --tags $(TAGS)

skills-install:
	@bin/skillsctl install

skills-diff:
	@bin/skillsctl diff
```
