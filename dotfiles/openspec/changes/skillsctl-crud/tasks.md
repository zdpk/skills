# Tasks: skillsctl CRUD & Multi-VM Sync

## Task 1: RegistryWriter — YAML 읽기/쓰기 엔진

**Priority:** P0
**Estimated:** 중

### Description

기존 `load_registry()` 함수를 `RegistryWriter` 클래스로 리팩토링.
skills 리스트의 원자적 CRUD + 정렬된 YAML 출력을 지원.

### Subtasks

- [ ] `RegistryWriter` 클래스 생성 (load, save, find_skill, find_similar)
- [ ] `add_skill()` — 중복 검사, 필드 순서 정렬, 알파벳순 삽입
- [ ] `remove_skill()` — 이름 검색, 제거, 유사 이름 제안
- [ ] `update_skill()` — 부분 업데이트, before/after 반환
- [ ] `ordered_skill()` — 필드 순서 보장 helper
- [ ] `find_similar()` — Levenshtein-like 유사 이름 검색
- [ ] timestamp 자동 설정 (created_at on add, updated_at on update)
- [ ] 기존 `load_registry()` 호출부를 RegistryWriter로 마이그레이션

### Acceptance Criteria

- `add_skill` 후 YAML이 알파벳순 정렬로 저장
- 중복 이름 추가 시 에러 발생
- `update_skill` 시 지정 필드만 변경, 나머지 보존
- `remove_skill` 시 존재하지 않는 이름은 에러 + 유사 이름 제안

---

## Task 2: `add` / `remove` / `update` CLI 명령어

**Priority:** P0
**Estimated:** 중

### Description

argparse subparser 3개 추가 + RegistryWriter 연동.

### Subtasks

- [ ] `cmd_add()` — 플래그 파싱, RegistryWriter.add_skill() 호출
- [ ] add 시 source=custom이면 SKILL.md 템플릿 자동 생성
- [ ] `cmd_remove()` — `--delete-files` 시 파일 삭제 + 빈 디렉토리 정리
- [ ] `cmd_remove()` — `--force` 없으면 확인 프롬프트 (stdin tty 체크)
- [ ] `cmd_update()` — `--add-tags`/`--remove-tags` 합집합/차집합 로직
- [ ] `cmd_update()` — `--set-tags`와 `--add-tags`/`--remove-tags` 상호 배타 검증
- [ ] 변경 전후 diff 출력 (add: 새 entry, remove: 제거된 entry, update: before/after)

### Acceptance Criteria

```bash
# add
skillsctl add test-skill --source custom --agent claude --tags dev,util
# → skills/custom/dev/test-skill/SKILL.md 생성
# → registry.yaml에 entry 추가

# remove
skillsctl remove test-skill --delete-files --force
# → registry.yaml에서 제거
# → skills/custom/dev/test-skill/ 디렉토리 삭제

# update
skillsctl update openspec --add-tags marketing
# → openspec entry의 tags에 marketing 추가
```

---

## Task 3: `import` 명령어

**Priority:** P1
**Estimated:** 소

### Description

외부 경로의 SKILL.md를 repo로 복사하고 registry에 등록.

### Subtasks

- [ ] `cmd_import()` — 경로 검증, SKILL.md 존재 확인
- [ ] agent 자동 추론 (경로에 `.codex/` → codex, `.claude/` → claude)
- [ ] 이름 자동 추출 (SKILL.md 상위 디렉토리명)
- [ ] `shutil.copytree()` — `.git`, `__pycache__`, `node_modules` 제외
- [ ] `import_origin` 필드에 원본 절대 경로 기록
- [ ] RegistryWriter.add_skill() 호출

### Acceptance Criteria

```bash
skillsctl import ~/other/.claude/skills/cool-skill/SKILL.md --tags dev
# → skills/custom/imported/cool-skill/SKILL.md 생성
# → registry.yaml에 source: custom, import_origin: ~/other/... entry 추가
```

---

## Task 4: `install` 명령어

**Priority:** P2
**Estimated:** 중

### Description

`source: downloaded` 스킬의 일괄 재설치. 멀티 VM bootstrap 핵심.

### Subtasks

- [ ] `cmd_install()` — downloaded 스킬 필터, install_source 파싱
- [ ] install_source 프로토콜 파서: `github:`, `url:`, `local:`
- [ ] `_install_github()` — `gh api` 또는 `gh repo clone` 사용
- [ ] `_install_url()` — `urllib.request.urlretrieve()` 사용
- [ ] `_install_local()` — `shutil.copytree()` 사용
- [ ] `--only` 필터, `--skip-existing` / `--force` 처리
- [ ] 성공/실패/스킵 카운트 리포트
- [ ] `gh` 미설치 시 안내 메시지

### Acceptance Criteria

```bash
# registry.yaml에 install_source가 있는 downloaded 스킬들을 재설치
skillsctl install
# → Installed: 15, Skipped: 10, Failed: 3
# → Failed: skill-a (gh not found), skill-b (404), skill-c (timeout)
```

---

## Task 5: `diff` 명령어

**Priority:** P2
**Estimated:** 소

### Description

registry 상태와 현재 VM 파일시스템을 비교하여 차이 리포트.

### Subtasks

- [ ] `cmd_diff()` — DiffEntry 수집 로직
- [ ] custom 스킬: path 필드 → 파일 존재 확인
- [ ] downloaded 스킬: 기본 설치 경로 → 파일 존재 확인
- [ ] 파일시스템 스캔 → 미등록 스킬 탐지 (EXTRA)
- [ ] 경로 이동 탐지 (MOVED) — 이름은 같지만 경로 다름
- [ ] table / json 출력 포맷
- [ ] 종료 코드: 차이 없으면 0, 있으면 1

### Acceptance Criteria

```bash
skillsctl diff
# Status      Name              Detail
# ──────────  ────────────────  ──────────────────────────
# MISSING     shadcn-ui         ~/.agents/skills/shadcn-ui/SKILL.md not found
# EXTRA       unknown-skill     ~/.claude/skills/unknown-skill/ not in registry
# OK          openspec          ✓
# → exit code 1 (differences found)

skillsctl diff --format json
# [{"status": "MISSING", "name": "shadcn-ui", "detail": "..."}]
```

---

## Task 6: Makefile & Documentation 업데이트

**Priority:** P2
**Estimated:** 소

### Description

Makefile에 신규 타겟 추가 + README 사용법 섹션.

### Subtasks

- [ ] Makefile에 `skills-add`, `skills-remove`, `skills-update`, `skills-import`, `skills-install`, `skills-diff` 타겟 추가
- [ ] `.PHONY` 업데이트
- [ ] bin/skillsctl `--help` 메시지에 신규 명령어 설명 추가

### Acceptance Criteria

- `make skills-add NAME=test SOURCE=custom AGENT=claude TAGS=dev` 동작
- `make skills-diff` 동작
- `skillsctl --help`에 6개 신규 명령어 표시
