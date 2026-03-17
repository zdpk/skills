# Proposal: skill-registry

## Problem

~75개의 Claude Code / Codex / OpenCode 스킬이 하드 전체 6개 위치에 분산되어 있다.

- `~/.claude/skills/` — 65개 (symlink 혼재)
- `~/.agents/skills/` — 28개 (다운로드)
- `~/.codex/skills/` — 72개 (flat copy, 가장 큼)
- `dotfiles/skills/custom/` — 29개 (커스텀 원본)
- `skills/.claude/skills/` — 5개 (메타 도구)
- 기타 고립 — 3개

**문제점:**
1. 어떤 스킬이 있는지 전체 인벤토리 파악이 불가능
2. 분류 체계 없음 (custom vs downloaded vs builtin vs agent-specific 구분 불가)
3. 특정 프로젝트 폴더에 필요한 스킬만 선택 배포할 방법 없음
4. 같은 스킬이 여러 위치에 복사되어 버전 불일치 발생
5. 스킬 추가/제거/업데이트 시 수동으로 여러 위치 관리 필요

## Goals

1. **Single Source of Truth**: 모든 스킬 메타데이터를 단일 레지스트리 파일로 관리
2. **Classification**: 각 스킬을 source(custom/downloaded/builtin/codex-exclusive), agent(claude/codex/opencode/universal) 기준 분류
3. **Tagging**: 스킬에 태그 부여 (dev, marketing, content, maple, openspec 등)
4. **Tag-based Deploy**: 태그 기반으로 특정 폴더의 `.claude/skills/`에 필요한 스킬만 symlink 배포
5. **CLI Interface**: `skillsctl` 명령어로 조회, 배포, 동기화 수행

## Non-Goals

- 스킬 내용(SKILL.md) 자체를 변경하지 않음
- 원격 스킬 저장소/마켓플레이스 구축 안 함
- Codex 빌트인/시스템 스킬은 관리 대상에서 제외 (레지스트리에는 기록하되 배포 안 함)
- 자동 업데이트 메커니즘 (수동 `sync` 명령으로 충분)

## Constraints

- 기존 `dotfiles/skills/custom/` 디렉토리 구조 유지 (카테고리 폴더)
- 기존 `~/.agents/skills/` 다운로드 경로 유지
- Bash 스크립트 기반 (의존성 최소화, 어디서든 실행)
- 레지스트리 파일 포맷: YAML (사람이 읽고 편집 가능)
- symlink 기반 배포 (복사 아님)

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| 기존 symlink 깨짐 | 스킬 로드 실패 | dry-run 모드 제공, 백업 후 배포 |
| 레지스트리 ↔ 실제 파일 불일치 | 유령 엔트리 | `skillsctl verify` 명령으로 정합성 검증 |
| 태그 체계 과도한 세분화 | 관리 복잡도 증가 | 초기 태그 10개 이내로 제한 |
