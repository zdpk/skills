# Development Workflow

## OpenSpec 필수: 선 스펙 후 구현

모든 코드 변경은 반드시 OpenSpec 스펙 기반 워크플로우를 따라야 한다. 구현 전에 항상 스펙을 먼저 작성할 것.

### 워크플로우

1. **탐색**: `/opsx:explore` - 문제 파악, 코드베이스 조사 (구현 금지, 읽기 전용)
2. **스펙 작성**: `/opsx:new <name>` 또는 `/opsx:ff <name>` - proposal → specs → design → tasks 순서로 산출물 생성
3. **구현**: `/opsx:apply` - tasks 기반으로 구현
4. **검증**: `/opsx:verify` - 스펙 대비 구현 검증
5. **아카이브**: `/opsx:archive` - 완료된 변경 아카이브

### 규칙

- 구현 요청을 받으면 먼저 OpenSpec change를 생성하고 스펙 산출물을 완성한 후 구현에 들어갈 것
- 사소한 수정(오타, 한 줄 변경)은 예외로 바로 수행 가능
- 프로젝트에 `openspec/` 디렉토리가 없으면 `openspec init`으로 초기화할 것
