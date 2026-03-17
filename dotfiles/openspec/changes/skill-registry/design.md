# Design: skill-registry

## Architecture

```
dotfiles/
├── skills/
│   ├── registry.yaml          ← 단일 레지스트리 (NEW)
│   ├── custom/                ← 기존 유지 (커스텀 스킬 원본)
│   │   ├── openspec/
│   │   ├── maple/
│   │   ├── youtube/
│   │   ├── social/
│   │   ├── imagegen/
│   │   ├── util/
│   │   ├── project/
│   │   ├── threads/           ← ~/.claude/skills/에서 이관 (NEW)
│   │   └── meta/              ← skills/.claude/skills/에서 이관 (NEW)
│   └── manifests/             ← 기존 유지 (참고용)
├── bin/
│   └── skillsctl              ← CLI 도구 (NEW)
└── ...
```

## Component: `registry.yaml`

위치: `skills/registry.yaml`

모든 스킬의 메타데이터를 YAML로 관리. 스킬 SKILL.md 파일 자체는 건드리지 않으며, 레지스트리는 메타데이터 레이어만 담당.

### 경로 규칙

| Source | path 형식 |
|--------|-----------|
| `custom` | `skills/custom/<category>/<name>` (repo 상대경로) |
| `downloaded` | `~/.agents/skills/<name>` (절대경로, tilde 허용) |
| `codex-exclusive` | `~/.codex/skills/<name>` (절대경로) |
| `builtin` | 경로 없음 (`path: null`) |

## Component: `skillsctl` CLI

Bash 스크립트. 외부 의존성: `yq` (YAML 파싱), `realpath`.

### Commands

```
skillsctl list [--source <s>] [--agent <a>] [--tag <t>] [--format table|json|yaml]
skillsctl deploy <profile|--tags t1,t2> --target <dir> [--agent claude|codex] [--clean] [--dry-run]
skillsctl verify [--fix]
skillsctl scan [--register]
skillsctl info <skill-name>
```

### `skillsctl list`

레지스트리에서 스킬 목록 조회. 필터링 지원.

```bash
skillsctl list                           # 전체
skillsctl list --tag dev                 # dev 태그만
skillsctl list --source custom           # 커스텀만
skillsctl list --agent codex             # codex 전용만
skillsctl list --format json             # JSON 출력
```

출력 형식 (table):
```
NAME                   SOURCE       AGENT      TAGS
openspec               custom       universal  dev, openspec
playwright-skill       downloaded   claude     dev, testing
maple-cover            custom       universal  maple, imagegen
...
(75 skills)
```

### `skillsctl deploy`

프로필 또는 태그 조합으로 대상 폴더에 symlink 배포.

**알고리즘:**
```
1. registry.yaml 로드
2. 프로필 → 태그 목록 확장 (profiles 섹션 참조)
3. skills 필터: tags 매치 AND disabled != true AND source != builtin
4. agent 호환성: --agent 옵션 또는 대상 폴더 자동 감지
   - .claude/ 존재 → claude
   - .codex/ 존재 → codex
   - 둘 다 없으면 → claude (기본)
5. 대상 디렉토리: <target>/.claude/skills/ 또는 <target>/.codex/skills/
6. 각 스킬에 대해:
   a. path 확인 (상대경로 → 절대경로 변환)
   b. SKILL.md 존재 확인
   c. symlink 생성: <target-skills-dir>/<name> → <resolved-path>
   d. 이미 존재하면 skip (--force로 재생성)
7. --clean: 레지스트리에 없는 symlink 제거
8. 결과 요약 출력
```

**dry-run 모드:**
```bash
skillsctl deploy dev --target ~/project --dry-run
# [DRY-RUN] Would create: ~/project/.claude/skills/openspec → /Users/x/.../openspec
# [DRY-RUN] Would create: ~/project/.claude/skills/vitest → /Users/x/.agents/skills/vitest
# [DRY-RUN] 12 skills would be deployed
```

### `skillsctl verify`

레지스트리 ↔ 파일 시스템 정합성 검증.

**검증 항목:**
1. 레지스트리 엔트리의 path에 SKILL.md 존재하는가
2. `skills/custom/` 하위에 SKILL.md가 있는데 레지스트리에 없는 스킬
3. `~/.agents/skills/` 하위에 SKILL.md가 있는데 레지스트리에 없는 스킬
4. name 중복 검사
5. 필수 필드 (name, source, agent, tags, path) 존재 검사
6. source/agent enum 값 유효성

`--fix` 옵션: 누락 스킬을 레지스트리에 자동 추가 (interactive).

### `skillsctl scan`

파일 시스템을 스캔하여 레지스트리에 없는 스킬을 발견.

**스캔 대상:**
- `skills/custom/` 하위 전체
- `~/.agents/skills/`
- `~/.codex/skills/` (codex-exclusive 후보)
- `~/.claude/skills/` (threads 등 직접 저장된 스킬)

`--register` 옵션: 발견된 스킬을 레지스트리에 추가 (interactive, 태그 입력 요청).

### `skillsctl info`

단일 스킬 상세 정보 표시.

```bash
skillsctl info openspec
# Name:        openspec
# Source:      custom
# Agent:       universal
# Tags:        dev, openspec
# Path:        skills/custom/openspec/openspec
# Description: Spec-driven development CLI wrapper
# Deployed to: ~/project-a, ~/project-b
```

## Edge Cases

1. **Tilde expansion**: `~/.agents/skills/x` → `/Users/x/.agents/skills/x` 변환 필요
2. **Broken symlinks**: deploy 시 기존 깨진 symlink 감지 후 재생성
3. **Circular symlinks**: 감지 후 경고
4. **대소문자 충돌**: macOS는 case-insensitive, name 중복 검사 시 lowercase 비교
5. **스킬 디렉토리에 SKILL.md 없는 경우**: 경고 후 skip (deploy 불가)

## Migration Plan

기존 분산된 스킬들을 레지스트리로 이관:

1. `skillsctl scan --register` 로 전체 스킬 발견 + 레지스트리 초안 생성
2. 수동으로 태그/분류 검토 및 조정
3. threads 8개 스킬을 `skills/custom/threads/` 로 이동
4. meta 5개 스킬을 `skills/custom/meta/` 로 이동
5. `skillsctl verify` 로 정합성 확인
6. `skillsctl deploy` 테스트 (dry-run → 실제 배포)
