# Spec: skillsctl CRUD & Multi-VM Commands

## 1. Commands Overview

```
skillsctl add <name>       # 새 스킬 등록
skillsctl remove <name>    # 스킬 제거
skillsctl update <name>    # 스킬 메타데이터 수정
skillsctl import <path>    # 외부 스킬 파일을 repo로 가져와서 등록
skillsctl install          # downloaded 스킬 일괄 재설치
skillsctl diff             # registry vs 현재 VM 상태 비교
```

## 2. `skillsctl add`

새 스킬을 registry.yaml에 등록하고, 필요 시 SKILL.md를 올바른 위치에 생성.

### Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--source` | yes | - | `custom`, `downloaded`, `codex-exclusive`, `builtin` |
| `--agent` | yes | - | 쉼표 구분: `claude`, `codex`, `any` |
| `--tags` | yes | - | 쉼표 구분 태그 목록 |
| `--category` | no | source에 따라 자동 | skills/custom/ 하위 카테고리 디렉토리 |
| `--description` | no | "" | 한 줄 설명 |
| `--path` | no | 자동 생성 | SKILL.md 경로 (source=custom일 때) |
| `--install-source` | no | - | source=downloaded일 때 설치 원본 URL/경로 |

### Behavior

1. 이름 중복 검사 (대소문자 무시)
2. source=custom이면:
   - `skills/custom/{category}/{name}/SKILL.md` 경로 자동 결정
   - 파일이 없으면 빈 SKILL.md 템플릿 생성
3. registry.yaml에 entry 추가 (알파벳 순 정렬 유지)
4. 변경 내역 stdout 출력

### Example

```bash
skillsctl add my-new-skill \
  --source custom \
  --agent claude \
  --tags dev,util \
  --description "My new skill description"
```

## 3. `skillsctl remove`

스킬을 registry에서 제거.

### Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--delete-files` | no | false | SKILL.md 파일도 함께 삭제 |
| `--force` | no | false | 확인 프롬프트 없이 삭제 |

### Behavior

1. 이름으로 registry entry 검색
2. 없으면 에러 (유사 이름 제안)
3. `--delete-files` 시 SKILL.md 파일 삭제 + 빈 디렉토리 정리
4. registry.yaml에서 entry 제거
5. 변경 내역 stdout 출력

### Example

```bash
skillsctl remove old-skill --delete-files
```

## 4. `skillsctl update`

기존 스킬의 메타데이터 수정.

### Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--add-tags` | no | - | 추가할 태그 (쉼표 구분) |
| `--remove-tags` | no | - | 제거할 태그 (쉼표 구분) |
| `--set-tags` | no | - | 태그 전체 교체 (쉼표 구분) |
| `--agent` | no | - | agent 필드 교체 |
| `--source` | no | - | source 필드 교체 |
| `--description` | no | - | description 필드 교체 |
| `--path` | no | - | path 필드 교체 |

### Behavior

1. 이름으로 entry 검색 (없으면 에러 + 유사 이름 제안)
2. 지정된 필드만 업데이트 (나머지 유지)
3. `--add-tags`/`--remove-tags`는 기존 태그에 합집합/차집합 연산
4. `--set-tags`는 `--add-tags`/`--remove-tags`와 동시 사용 불가
5. registry.yaml 저장
6. 변경 전후 diff 출력

### Example

```bash
skillsctl update openspec --add-tags marketing --agent claude,codex
```

## 5. `skillsctl import`

외부 경로의 SKILL.md를 repo 내 `skills/custom/` 하위로 복사하고 registry에 등록.

### Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--name` | no | 디렉토리명에서 추출 | 스킬 이름 |
| `--category` | no | `imported` | 카테고리 디렉토리 |
| `--agent` | no | 경로에서 추론 | `.codex/` → codex, `.claude/` → claude |
| `--tags` | yes | - | 태그 목록 |

### Behavior

1. 소스 경로 검증 (SKILL.md 존재 확인)
2. 이름 중복 검사
3. `skills/custom/{category}/{name}/` 디렉토리 생성
4. SKILL.md 복사 (+ 같은 디렉토리의 부속 파일도 복사)
5. registry.yaml에 `source: custom` entry 추가
6. 원본 경로를 `import_origin` 필드에 기록 (추적용)

### Example

```bash
skillsctl import ~/other-project/.claude/skills/cool-skill/SKILL.md --tags dev
```

## 6. `skillsctl install`

registry에 등록된 `source: downloaded` 스킬들을 일괄 재설치.

### Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--target` | no | `~/.agents/skills/` | 설치 대상 디렉토리 |
| `--only` | no | 전체 | 특정 스킬만 설치 (쉼표 구분) |
| `--skip-existing` | no | true | 이미 있으면 건너뛰기 |
| `--force` | no | false | 기존 파일 덮어쓰기 |

### Behavior

1. `source: downloaded` 스킬 목록 추출
2. 각 스킬의 `install_source` 필드 확인 (없으면 skip + 경고)
3. install_source 타입별 처리:
   - `github:<org>/<repo>/<path>` → gh api로 다운로드
   - `url:<url>` → curl/wget
   - `local:<path>` → 복사
4. 성공/실패 카운트 리포트

### registry.yaml 스키마 확장

```yaml
skills:
  - name: shadcn-ui
    source: downloaded
    install_source: "github:anthropics/courses/skill_packs/shadcn-ui"
    # ... 기존 필드
```

## 7. `skillsctl diff`

registry.yaml에 등록된 상태와 현재 VM 파일시스템 상태를 비교.

### Flags

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--format` | no | `table` | 출력 형식: `table`, `json` |

### Output

```
Status      Name              Detail
──────────  ────────────────  ──────────────────────────
MISSING     shadcn-ui         ~/.agents/skills/shadcn-ui/SKILL.md not found
EXTRA       unknown-skill     ~/.claude/skills/unknown-skill/ not in registry
MOVED       openspec          registered: skills/custom/... actual: ~/.claude/skills/...
OK          threads           ✓
```

### Behavior

1. registry의 모든 custom 스킬 → path 존재 확인
2. registry의 모든 downloaded 스킬 → 기본 설치 경로 존재 확인
3. 파일시스템 스캔 → registry에 없는 스킬 탐지 (기존 `scan`과 유사하나 비교 관점)
4. 상태: `OK`, `MISSING`, `EXTRA`, `MOVED`, `MODIFIED` (mtime 비교)

## 8. Registry Schema v1.1 (하위 호환)

기존 스키마에 optional 필드 추가:

```yaml
skills:
  - name: string          # required (기존)
    source: enum          # required (기존)
    agent: list[string]   # required (기존)
    tags: list[string]    # required (기존)
    path: string          # optional (기존)
    description: string   # optional (기존)
    # ── v1.1 신규 (전부 optional) ──
    install_source: string  # downloaded 스킬의 원본 소스
    import_origin: string   # import한 스킬의 원래 경로
    created_at: string      # ISO 8601 등록 일시
    updated_at: string      # ISO 8601 최종 수정 일시
```

## 9. YAML Write Rules

registry.yaml 쓰기 시 일관성 보장:

1. skills 리스트는 `name` 기준 알파벳 오름차순 정렬
2. 각 entry 내 필드 순서: name, source, agent, tags, path, description, install_source, import_origin, created_at, updated_at
3. 빈 optional 필드는 생략 (null이나 "" 쓰지 않음)
4. 태그 리스트는 알파벳 순 정렬
5. 주석(# ── Section ──)은 source 그룹 변경 시 삽입
