# Tasks: skill-registry

## Task 1: Create `skills/registry.yaml` with full inventory

**파일**: `skills/registry.yaml`
**수락 기준**: 전체 ~75개 스킬이 등록되고, `yq` 로 파싱 가능

```yaml
version: 1

profiles:
  dev:
    description: "개발 프로젝트 공통"
    tags: [dev, openspec, util, meta]
  marketing:
    description: "마케팅/콘텐츠/SNS"
    tags: [content, social, marketing]
  maple:
    description: "메이플스토리 BGM 프로젝트"
    tags: [maple, content, imagegen, youtube]
  youtube:
    description: "YouTube 콘텐츠 제작"
    tags: [youtube, content, imagegen]
  threads:
    description: "Threads SNS 자동화"
    tags: [social, content, marketing]
  full:
    description: "모든 스킬"
    tags: ["*"]
```

### 등록할 스킬 전체 목록:

**Custom - OpenSpec (11)**: openspec, openspec-explore, openspec-new-change, openspec-ff-change, openspec-apply-change, openspec-verify-change, openspec-archive-change, openspec-bulk-archive-change, openspec-continue-change, openspec-onboard, openspec-sync-specs
- source: custom, agent: universal, tags: [dev, openspec]
- path: skills/custom/openspec/<name>

**Custom - Maple (7)**: maple-cover, maple-character, maple-background, maple-style, suno-prompt, maplestory-idea
- source: custom, agent: universal, tags: [maple, content]
- path: skills/custom/maple/<name>

**Custom - YouTube (4)**: yt-topic, yt-research, yt-script, yt-storyboard
- source: custom, agent: universal, tags: [youtube, content]
- path: skills/custom/youtube/<name>

**Custom - Social (1)**: x-research
- source: custom, agent: universal, tags: [social]
- path: skills/custom/social/<name>

**Custom - ImageGen (2)**: imagegen-chatgpt, imagegen-flow
- source: custom, agent: universal, tags: [imagegen, content]
- path: skills/custom/imagegen/<name>

**Custom - Util (3)**: re, switch-google-account, flow-ingredients-sync
- source: custom, agent: universal, tags: [util]
- path: skills/custom/util/<name>

**Custom - Project (2)**: manual-authoring, manual-sync
- source: custom, agent: universal, tags: [dev]
- path: skills/custom/project/<name>

**Custom - Threads (8)** ← `~/.claude/skills/`에서 이관: threads, threads-account, threads-context, threads-publish, threads-reference, threads-research, threads-topic, threads-write
- source: custom, agent: claude, tags: [social, content, marketing]
- path: skills/custom/threads/<name>

**Custom - Meta (5)** ← `skills/.claude/skills/`에서 이관: verify-skill-format, verify-implementation, verify-skillpack, manage-skills, gemini-watermark-removal
- source: custom, agent: claude, tags: [meta]
- path: skills/custom/meta/<name>

**Custom - Isolated (2)**: hex-usecase-scaffold-kotlin-spring-jpa, obsidian-cli
- source: custom, agent: universal, tags: [dev]
- path: 절대경로

**Downloaded (27)**: agent-browser, apify-trend-analysis, axum, brainstorming, content-strategy, copywriting, find-skills, nextjs-app-router-patterns, playwright-skill, remotion-best-practices, rust-testing, shadcn-ui, short-form-video, shorts-script-personality, skill-creator, tailwind-v4-shadcn, tweet-writer, vercel-react-best-practices, vitest, writing-x-posts, x-publish, claude-api, platform-optimization, openspec-archiving, openspec-context-loading, openspec-implementation, openspec-proposal-creation
- source: downloaded, agent: claude, tags: 개별 할당
- path: ~/.agents/skills/<name>

**Codex-Exclusive (14)**: atlas, gh-address-comments, gh-fix-ci, imagegen, linear, openai-docs, pdf, playwright, screenshot, security-best-practices, security-ownership-map, security-threat-model, sora, spreadsheet
- source: codex-exclusive, agent: codex, tags: 개별 할당
- path: ~/.codex/skills/<name>

**Builtin (3)**: codex-skill-creator, codex-skill-installer, codex-openai-docs-system
- source: builtin, agent: codex, tags: []
- path: null

---

## Task 2: Migrate threads skills to `skills/custom/threads/`

**파일**: `skills/custom/threads/` 디렉토리
**소스**: `~/.claude/skills/threads*` (8개 디렉토리, symlink 아닌 실제 파일)
**수락 기준**: 8개 스킬 이동 완료, 원본 위치에 symlink 생성

```bash
# 각 스킬에 대해:
for skill in threads threads-account threads-context threads-publish threads-reference threads-research threads-topic threads-write; do
  cp -r ~/.claude/skills/$skill skills/custom/threads/$skill
  rm -rf ~/.claude/skills/$skill
  ln -s $(pwd)/skills/custom/threads/$skill ~/.claude/skills/$skill
done
```

---

## Task 3: Migrate meta skills to `skills/custom/meta/`

**파일**: `skills/custom/meta/` 디렉토리
**소스**: `/Users/x/workspace/personal/skills/.claude/skills/` (5개)
**수락 기준**: 5개 스킬 이동 완료

```bash
for skill in verify-skill-format verify-implementation verify-skillpack manage-skills gemini-watermark-removal; do
  cp -r /Users/x/workspace/personal/skills/.claude/skills/$skill skills/custom/meta/$skill
done
```

---

## Task 4: Create `bin/skillsctl` CLI

**파일**: `bin/skillsctl`
**의존성**: `yq` (v4+), `realpath`
**수락 기준**: 아래 명령어 모두 동작

### 4.1: 기본 구조 + `list` 명령

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REGISTRY="$REPO_ROOT/skills/registry.yaml"

cmd_list() { ... }
cmd_deploy() { ... }
cmd_verify() { ... }
cmd_scan() { ... }
cmd_info() { ... }

case "${1:-help}" in
  list)    shift; cmd_list "$@" ;;
  deploy)  shift; cmd_deploy "$@" ;;
  verify)  shift; cmd_verify "$@" ;;
  scan)    shift; cmd_scan "$@" ;;
  info)    shift; cmd_info "$@" ;;
  help|-h) cmd_help ;;
  *)       echo "Unknown command: $1"; cmd_help; exit 1 ;;
esac
```

### 4.2: `list` 구현

- `--source`, `--agent`, `--tag` 필터 지원
- `--format table|json|yaml` 출력 포맷
- 기본: table 형식 (NAME, SOURCE, AGENT, TAGS)

### 4.3: `deploy` 구현

- 프로필명 또는 `--tags` 직접 지정
- `--target <dir>` 필수
- `--agent claude|codex` 옵션 (자동 감지 가능)
- `--dry-run` 모드
- `--clean` 비매칭 symlink 제거
- symlink 생성 로직 (상대경로 → 절대경로 변환, tilde expansion)

### 4.4: `verify` 구현

- 레지스트리 엔트리 path에 SKILL.md 존재 여부
- skills/custom/ 하위 미등록 스킬 감지
- name 중복 검사
- 필수 필드 검사
- 종료 코드: 0(pass), 1(fail)

### 4.5: `scan` 구현

- `skills/custom/`, `~/.agents/skills/`, `~/.codex/skills/`, `~/.claude/skills/` 스캔
- 레지스트리에 없는 스킬 표시
- `--register` 옵션: 발견된 스킬을 레지스트리에 추가

### 4.6: `info` 구현

- 단일 스킬 상세 정보 출력
- 어떤 target에 배포되었는지 (symlink 역추적)

---

## Task 5: Update Makefile

**파일**: `Makefile`
**수락 기준**: `make skills-*` 타겟 추가

```makefile
skills-list:
	@bin/skillsctl list

skills-verify:
	@bin/skillsctl verify

skills-deploy:
	@echo "Usage: make skills-deploy PROFILE=dev TARGET=~/my-project"
	@bin/skillsctl deploy $(PROFILE) --target $(TARGET)

skills-scan:
	@bin/skillsctl scan
```

---

## Task 6: Verify full pipeline

**수락 기준**: 아래 시나리오 모두 통과

```bash
# 1. 레지스트리 검증
bin/skillsctl verify

# 2. 스킬 목록 조회
bin/skillsctl list
bin/skillsctl list --tag dev
bin/skillsctl list --source custom
bin/skillsctl list --agent codex

# 3. dry-run 배포
bin/skillsctl deploy dev --target /tmp/test-project --dry-run

# 4. 실제 배포 + 확인
mkdir -p /tmp/test-project
bin/skillsctl deploy dev --target /tmp/test-project
ls -la /tmp/test-project/.claude/skills/

# 5. 스킬 정보 조회
bin/skillsctl info openspec

# 6. 스캔
bin/skillsctl scan
```
