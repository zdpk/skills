# Repo Rules

이 저장소는 AI coding tool dotfiles와 skill source의 source of truth다.

# Workflow

- 새 skill 또는 기존 skill 수정에는 `skill-creator` 지침을 먼저 따른다.
- 원본 skill은 `skills/<category>/<skill-name>/` 아래에 둔다.
- 언어 관련 skill은 `skills/lang/` 아래에 둔다.
- 전역 위치인 `~/.agents/skills`나 `~/.codex/skills`를 직접 수정하지 않는다.
- root `skills/` 배포는 `scripts/install.sh` 또는 `make global-skills-*`로 한다.
- root `skills/` 관리는 Rust CLI `sk` 또는 `make sk-*`로 확인한다.
- 수정 후 `make global-skills-validate`와 `make sk-test`를 실행한다.

# Skill Rules

- 각 skill에는 `SKILL.md`가 필수다.
- `SKILL.md` frontmatter에는 `name`과 `description`만 둔다.
- 언어 skill은 ISO 639-1 코드로 `<source>-<target>` 또는 `<language>-core` 형식을 쓴다.
- skill 버전은 `skills/registry.toml`에서 관리한다.
- skill 폴더 안에는 필요한 리소스만 둔다.
- 반복 실행이 필요한 로직은 `scripts/`에 둔다.
- 긴 참고 자료는 `references/`에 둔다.
- 출력에 재사용할 파일은 `assets/`에 둔다.
- skill 내부에 `README.md`, `CHANGELOG.md`, `INSTALL.md` 같은 운영 문서를 만들지 않는다.

# Safety

- 기존 전역 skill 디렉터리를 덮어쓰지 않는다.
- 설치 스크립트가 만든 symlink만 갱신한다.
- 다른 사람이 만든 변경을 되돌리지 않는다.
- 스크립트를 바꾸면 실제 명령으로 검증한다.
