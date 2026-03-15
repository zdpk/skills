# Vibe UX Radar Memory

## 2026-03-04 Run
- `x-research` CLI first attempted, but blocked by missing `X_BEARER_TOKEN`.
- Fallback used: X web index + Thread Reader mirrors.
- Collected high-signal references around v0, Lovable, Bolt, Replit Agent, Cursor, shadcn/ui, Tailwind, Radix, Motion, Supabase, Vercel.
- Strongest recurring themes: component-tokenized UI systems, prompt-first layout specs, and fast shipping loops with visual refinement.
- Noted risk pattern: security + data-access misconfigurations (especially Supabase/RLS in generated apps) and “template sameness.”
- Coverage gaps: limited real-time engagement metrics and likely missing posts that are not mirrored/indexed.

Run timestamp: 2026-03-04 03:15:00 +0900

## 2026-03-06 Run
- `x-research` CLI 재시도 결과: `X_BEARER_TOKEN` 미설정으로 X API 호출 불가.
- Fallback 수행: Thread Reader + X 웹 인덱스 결과를 조합해 UI/UX 중심 vibe-coding 포스트 샘플 수집.
- 상위 신호: v0/Lovable/Bolt/Cursor/Replit Agent 비교, shadcn/ui+Tailwind+Radix 기반 컴포넌트 설계, Supabase 연동 속도/보안 트레이드오프.
- 반복 패턴: 프롬프트로 정보구조(IA) 먼저 고정 -> 컴포넌트 토큰화 -> 미세 인터랙션/애니메이션 보강.
- 안티패턴: 템플릿 동형화, RLS 미설정·데이터 접근 오설정, 시각적 완성도만 높고 사용성 검증 부재.
- 커버리지 갭: 비미러/삭제/비공개 트윗 및 실시간 engagement 지표(조회수/북마크) 누락.

Run timestamp: 2026-03-06 09:04:13 +0900

## 2026-03-09 Run
- `x-research` CLI 우선 실행: `X_BEARER_TOKEN` 미설정으로 X API 호출 불가(동일 이슈 재발).
- Fallback 수행: Thread Reader 미러 + 공개 X 인덱스 검색 결과를 조합해 UI/UX 중심 vibe-coding 포스트를 수집.
- 고신호 축: v0 Design Mode(shadcn/Tailwind), Lovable+Supabase 실전 구축/보안(RLS), Cursor/Replit Agent/Bolt 비교 담론.
- 반복 패턴: IA/레이아웃 프롬프트 선고정 -> shadcn+Tailwind 컴포넌트화 -> Radix 접근성/상태 -> Motion 미세 인터랙션.
- 안티패턴: 템플릿 동형화, UI 화려함 대비 정보구조/퍼널 미검증, Supabase 권한 설정 누락.
- 커버리지 갭: X API 미사용으로 실시간 engagement/삭제·비공개 트윗/비미러 스레드 누락 가능.

Run timestamp: 2026-03-09 09:03:54 +0900
Run time: ~14m

## 2026-03-11 Run
- `x-research` CLI 우선 실행: `X_BEARER_TOKEN` 미설정으로 X API 호출 불가(`Error: X_BEARER_TOKEN not found`).
- Fallback 수행: Thread Reader 미러 + 공개 X 인덱스 검색으로 UI/UX 중심 vibe-coding 고신호 포스트 표본 수집(도구군: v0/Lovable/Bolt/Replit Agent/Cursor/shadcn/Tailwind/Radix/Motion/Supabase/Vercel).
- 반복 설계 패턴 강화 확인: IA-우선 프롬프트 -> 컴포넌트/토큰화(shadcn+Tailwind+Radix) -> Motion 미세 인터랙션 -> Vercel 배포 루프.
- 안티패턴 재확인: 템플릿 동형화, 프롬프트 과적합(요구사항 미고정), Supabase RLS/권한 정책 누락에 따른 보안 리스크.
- 커버리지 갭: X API 미사용으로 실시간 engagement 정밀치(노출/북마크), 삭제·비공개 트윗, 비미러 스레드 누락 가능.

Run timestamp: 2026-03-11 09:03:24 +0900
Run time: ~9m

## 2026-03-13 Run
- `x-research` CLI 우선 실행 결과: `Error: X_BEARER_TOKEN not found`로 X API 호출 불가.
- Fallback 수행: Thread Reader 미러 + 공개 X 인덱스 결과로 vibe-coding UI/UX 포스트 표본 수집.
- 고신호 링크 축: v0 Design Mode(shadcn/Tailwind), Lovable+Supabase 실전 워크플로우, Cursor/Bolt/Replit Agent 비교 포스트.
- 도구 빈도(표본 기준): v0/Lovable 최다, Cursor/Bolt 중간, Radix/Motion/Replit Agent는 저빈도.
- 반복 패턴: IA-우선 프롬프트 -> 컴포넌트 토큰화 -> 미세 인터랙션 -> 빠른 배포/피드백 루프.
- 안티패턴: 템플릿 동형화, RLS 누락, 화려한 모션 대비 사용성 검증 부족.
- 커버리지 갭: X API 미사용으로 실시간 engagement 수치/삭제·비공개 트윗/비미러 스레드 누락 가능.

Run timestamp: 2026-03-13 09:06:08 +0900
Run time: ~11m
