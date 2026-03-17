# Proposal: skillsctl CRUD & Multi-VM Sync

## Status: draft

## Problem

현재 `skillsctl`은 읽기 전용(list, info, verify, scan, deploy)만 지원한다.
스킬을 추가/삭제/수정하려면 `registry.yaml`을 직접 편집해야 하며, 이는:

1. **오류 발생 쉬움** — YAML 구조, 필수 필드, enum 값을 수동으로 맞춰야 함
2. **멀티 VM 불편** — 여러 머신에서 같은 registry를 유지하려면 수동 동기화 필요
3. **외부 스킬 도입 번거로움** — 다른 프로젝트에서 발견한 스킬을 repo로 가져오는 절차 없음
4. **다운로드 스킬 재설치 불가** — VM을 바꾸면 downloaded 스킬을 수동으로 다시 설치해야 함

## Goals

- `skillsctl add/remove/update`로 registry.yaml CRUD 완전 자동화
- `skillsctl import`로 외부 경로의 스킬을 repo로 가져오기
- `skillsctl install`로 downloaded 스킬 일괄 재설치 (멀티 VM bootstrap)
- `skillsctl diff`로 현재 VM 상태와 registry 차이 확인
- Git 기반 동기화: push/pull만으로 모든 VM이 동일한 skill set 유지

## Non-Goals

- 자동 push/pull (사용자가 git 명령 직접 수행)
- 스킬 내용 자동 생성 (SKILL.md 작성은 별도)
- 원격 스킬 마켓플레이스 연동
- Codex exclusive 스킬 관리 (codex 자체 시스템으로 관리)

## Constraints

- Python 3.9+ 표준 라이브러리만 사용 (외부 의존성 없음)
- 기존 skillsctl 명령어/인터페이스 하위 호환
- registry.yaml 스키마 v1 하위 호환 (새 필드는 optional)
- 단일 파일 CLI 유지 (bin/skillsctl 하나)

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| registry.yaml 병합 충돌 | 멀티 VM에서 동시 편집 시 충돌 | skill 단위 정렬 규칙 + 충돌 시 가이드 |
| import 시 경로 깨짐 | 원본 경로가 VM마다 다름 | repo 내 상대 경로로 정규화 |
| downloaded 스킬 설치 실패 | 외부 소스 변경/삭제 | install 시 실패 스킬 리포트, skip 옵션 |
