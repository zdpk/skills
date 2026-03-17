# Spec: Skill Registry

## Registry Schema

레지스트리는 `skills/registry.yaml` 파일 하나로 관리한다.

```yaml
# skills/registry.yaml
version: 1

# 태그별 배포 대상 정의
profiles:
  dev:
    description: "개발 프로젝트 공통"
    tags: [dev, openspec, util]
  marketing:
    description: "마케팅/콘텐츠"
    tags: [content, social, marketing]
  maple:
    description: "메이플스토리 BGM 프로젝트"
    tags: [maple, content, imagegen]
  fullstack:
    description: "모든 스킬"
    tags: ["*"]

# 스킬 목록
skills:
  - name: openspec
    source: custom          # custom | downloaded | builtin | codex-exclusive
    agent: universal        # claude | codex | opencode | universal
    tags: [dev, openspec]
    path: skills/custom/openspec/openspec
    description: "Spec-driven development CLI wrapper"

  - name: playwright-skill
    source: downloaded
    agent: claude
    tags: [dev, testing]
    origin: "~/.agents/skills/playwright-skill"
    description: "Playwright E2E testing patterns"
```

## Skill Entry Fields

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `name` | ✅ | string | 스킬 고유 이름 (kebab-case) |
| `source` | ✅ | enum | `custom`, `downloaded`, `builtin`, `codex-exclusive` |
| `agent` | ✅ | enum | `claude`, `codex`, `opencode`, `universal` |
| `tags` | ✅ | string[] | 1개 이상의 태그 |
| `path` | ✅ | string | 스킬 디렉토리 경로 (repo 상대경로 또는 절대경로) |
| `description` | ✅ | string | 한 줄 설명 |
| `origin` | ❌ | string | downloaded 스킬의 원본 경로 또는 URL |
| `disabled` | ❌ | bool | true면 배포에서 제외 (기본 false) |

## Source Classification

| Source | 정의 | 예시 |
|--------|------|------|
| `custom` | 직접 작성, dotfiles repo에서 관리 | openspec, maple-cover, yt-topic |
| `downloaded` | 커뮤니티/마켓에서 설치, `~/.agents/skills/`에 위치 | playwright-skill, shadcn-ui, vitest |
| `builtin` | AI agent에 내장 (관리 대상 아님, 기록용) | codex skill-creator, skill-installer |
| `codex-exclusive` | Codex에서만 사용 가능한 스킬 | atlas, sora, imagegen (OpenAI) |

## Agent Classification

| Agent | 정의 |
|-------|------|
| `claude` | Claude Code에서만 사용 |
| `codex` | Codex에서만 사용 |
| `opencode` | OpenCode에서만 사용 |
| `universal` | 모든 agent에서 사용 가능 |

## Tag Taxonomy (초기)

| Tag | 용도 |
|-----|------|
| `dev` | 일반 개발 (테스팅, 프레임워크, 코드품질) |
| `openspec` | OpenSpec 워크플로우 |
| `content` | 콘텐츠 제작 (영상, 글, 이미지) |
| `social` | SNS 자동화 (X, Threads) |
| `marketing` | 마케팅/카피라이팅 |
| `maple` | 메이플스토리 프로젝트 전용 |
| `imagegen` | 이미지 생성 |
| `youtube` | YouTube 파이프라인 |
| `util` | 유틸리티/범용 |
| `meta` | 스킬 관리/검증 도구 |

## Profile-based Deploy

프로필은 태그 조합으로 정의되며, 특정 폴더에 배포할 때 사용:

```bash
# dev 프로필의 스킬들을 ~/project-a/.claude/skills/에 배포
skillsctl deploy dev --target ~/project-a

# marketing 프로필 배포
skillsctl deploy marketing --target ~/marketing-site

# 특정 태그 조합으로 직접 배포
skillsctl deploy --tags dev,openspec --target ~/my-project
```

배포 동작:
1. 레지스트리에서 매칭 태그 스킬 필터링
2. `source=builtin`인 스킬 제외
3. agent 호환성 체크 (대상 폴더의 agent 타입)
4. 대상 폴더 `.claude/skills/`에 symlink 생성
5. 기존에 있던 비매칭 symlink는 건드리지 않음 (`--clean` 옵션으로 제거 가능)

## Scenarios

### S1: 새 커스텀 스킬 추가
1. `skills/custom/<category>/<name>/SKILL.md` 작성
2. `registry.yaml`에 엔트리 추가
3. `skillsctl verify` 실행 → 경로 유효성 확인
4. `skillsctl deploy <profile> --target <dir>` 실행

### S2: 다운로드 스킬 등록
1. `~/.agents/skills/<name>` 에 이미 설치된 스킬 확인
2. `registry.yaml`에 엔트리 추가 (origin 필드에 원본 경로)
3. `skillsctl verify` 실행

### S3: 프로젝트 폴더에 스킬 배포
1. `skillsctl deploy dev --target ~/workspace/my-project`
2. `~/workspace/my-project/.claude/skills/` 에 symlink 생성
3. `skillsctl list --target ~/workspace/my-project` 로 배포 상태 확인

### S4: 스킬 제거
1. `registry.yaml`에서 `disabled: true` 설정 또는 엔트리 삭제
2. `skillsctl deploy <profile> --target <dir> --clean` 실행 → 해당 symlink 제거

### S5: 레지스트리 정합성 검증
1. `skillsctl verify` 실행
2. 경로에 SKILL.md 없는 엔트리 → 경고
3. 파일 존재하지만 레지스트리에 없는 스킬 → 경고
4. 중복 name → 에러
