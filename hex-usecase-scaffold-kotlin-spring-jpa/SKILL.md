---
name: "hex-usecase-scaffold-kotlin-spring-jpa"
description: "Generate a Hexagonal (Ports & Adapters) scaffold for a new UseCase in Kotlin + Spring Boot + JPA, from a short requirement."
version: "0.1.0"
tags: ["kotlin", "spring-boot", "jpa", "hexagonal", "scaffold"]
inputs:
  - name: "requirement"
    description: "Short requirement text: what the feature does, main entity, key validations, side effects (DB write, external call, event), and API shape."
  - name: "naming"
    description: "Names for bounded context/module (optional), usecase name (e.g., CreateOrder), entity name (e.g., Order), and endpoint path/method (optional)."
  - name: "project_conventions"
    description: "Package/module layout and conventions (defaults applied if omitted): base package, layer packages, dto/mapper/test style, error handling style."
  - name: "mode"
    description: "Either 'dry-run' (default) or 'apply'. Dry-run outputs planned files + diffs without writing."
outputs:
  - name: "scaffold_plan"
    description: "A deterministic plan: files to create, file contents (or diffs), and how layers connect (Controller -> Application -> Ports -> Adapters)."
  - name: "generated_files"
    description: "When mode=apply: created/updated files with exact paths. When dry-run: proposed file list + contents."
---

## When to use
- You are adding a new feature/usecase and want a consistent Hexagonal skeleton quickly.
- You want to enforce "thin controller, application orchestrates, domain pure, adapters at edges".
- You want repeatable naming/structure for DTOs, ports, adapters, and tests.

## When NOT to use
- The change is a small local refactor that should touch only one layer.
- The domain model is unstable and you are not ready to commit to port boundaries yet.
- The project does not use a recognizable Hexagonal layout (use a different scaffold skill).

## Required context
- Project is Kotlin + Spring Boot + (JPA/Hibernate) and uses a layered package structure compatible with Hexagonal:
  - `domain` (entities/value objects/domain services)
  - `application` (usecases, ports)
  - `adapter.in` (web/controller)
  - `adapter.out` (persistence, external clients)
- You must know (or accept defaults for):
  - Base package (e.g., `com.example.app`)
  - Where controllers live
  - Where ports live (in/out ports)
  - Naming convention for DTOs and errors
- Assumption defaults (override via project_conventions):
  - Base package: `com.example`
  - Packages:
    - `domain.*`
    - `application.usecase.*`
    - `application.port.in.*`
    - `application.port.out.*`
    - `adapter.in.web.*`
    - `adapter.out.persistence.*`
  - Tests:
    - Unit tests for application usecase with mocks
    - Optional integration test skeleton for persistence adapter

## Procedure
1) Parse inputs
   - Extract: usecase name (VerbNoun), entity name, command/query type, endpoint (optional).
   - Determine side effects:
     - DB write? -> OutPort + PersistenceAdapter
     - External HTTP call? -> OutPort + ClientAdapter
     - Event publish? -> OutPort + EventAdapter
   - Determine validations:
     - Input validation (request/DTO level)
     - Domain invariants (domain constructors/methods)

2) Decide file set (scaffold plan)
   - Always generate:
     - InPort interface (application.port.in)
     - Command/Query DTO (application.usecase.dto OR application.port.in.dto)
     - UseCase service implementation (application.usecase)
     - Controller (adapter.in.web) if endpoint is provided, otherwise omit controller
     - Error model (sealed class) for usecase-level errors (application.usecase.error)
     - Unit test skeleton (application usecase)
   - Conditionally generate:
     - OutPort interface (application.port.out) if DB/external/event side effect exists
     - OutAdapter (adapter.out.*) if outport exists
     - JPA Entity/Repository skeleton ONLY if explicitly requested in requirement (never assume schema)
     - Mapper skeleton if DTO <-> domain translation is non-trivial

3) Produce wiring (how it connects)
   - Controller -> InPort (interface)
   - UseCase implements InPort and depends on OutPort(s)
   - AdapterOut implements OutPort(s)
   - Spring configuration:
     - Prefer component scanning with `@Service`, `@Component`
     - If multiple implementations exist, use `@Qualifier` and generate the qualifier names

4) Dry-run output (default)
   - Output exact paths + file contents + minimal “integration notes”
   - If any file already exists:
     - Do NOT overwrite in dry-run; show a diff-style patch proposal

5) Apply mode (only when mode=apply)
   - Create new files; update existing files only when:
     - The update is additive (e.g., adding a method to an interface with no breaking signature changes)
   - Never delete files
   - After writing, re-summarize created/updated paths

## Output format
- Always return a sectioned artifact with:
  1) `Scaffold Summary` (usecase, entity, side effects, generated layers)
  2) `File Plan` (path list)
  3) `Files` (each file path + full content OR unified diff if file exists)
  4) `Wiring Notes` (how beans are resolved, where to call what)
  5) `Next Actions` (what developer must fill in)

### File naming rules
- InPort: `<UseCaseName>UseCase` (e.g., `CreateOrderUseCase`)
- Command DTO: `<UseCaseName>Command`
- Result DTO: `<UseCaseName>Result` (or `Unit` if none)
- UseCase impl: `<UseCaseName>Service`
- OutPort: `<Purpose>Port` (e.g., `OrderRepositoryPort`, `PaymentClientPort`, `OrderEventPort`)
- AdapterOut: `<Purpose>Adapter` (e.g., `OrderPersistenceAdapter`)
- Controller: `<EntityName>Controller` or `<UseCaseName>Controller` based on endpoint granularity

## Guardrails (Safety & Quality)
- Default to `dry-run`. Only write files in `apply`.
- Never overwrite existing files silently. If a file exists, output a diff and require apply.
- Never invent DB schema changes. If persistence is needed, generate ports/adapters only unless schema is specified.
- Keep domain pure:
  - Domain objects must not import Spring/JPA/Adapter packages.
- Keep controller thin:
  - No JPA repository calls in controller
  - No transaction/business logic in controller
- Usecase errors:
  - Define explicit error types (sealed classes) rather than throwing generic exceptions.
- Do not add secrets, credentials, or environment-specific endpoints.

## Edge cases & Recovery
- Missing names:
  - If usecase/entity names are missing, derive from requirement using VerbNoun heuristics and state the derivation.
- Existing conflicting classes:
  - If a class name/path already exists, propose an alternative suffix (e.g., `V2`, `New`, or more specific purpose) and show both options in dry-run.
- Multiple side effects:
  - Generate multiple outports and keep usecase orchestrating them in a clear order.
- Transaction boundaries:
  - If DB write is involved, add `@Transactional` on UseCase service (not controller) and explain it in Wiring Notes.

## Examples
### Example 1
**Input**
requirement:
- "학생이 이메일로 회원가입한다. 이메일은 중복될 수 없다. 가입 시 환영 이메일을 보낸다."
naming:
- basePackage: com.sn.app
- usecase: RegisterStudent
- entity: Student
- endpoint: POST /api/students/register
mode: dry-run

**Output**
Scaffold Summary:
- UseCase: RegisterStudent
- Entity: Student
- Side effects: DB write, send email
File Plan:
- com/sn/app/application/port/in/RegisterStudentUseCase.kt
- com/sn/app/application/usecase/RegisterStudentService.kt
- com/sn/app/application/usecase/dto/RegisterStudentCommand.kt
- com/sn/app/application/usecase/dto/RegisterStudentResult.kt
- com/sn/app/application/usecase/error/RegisterStudentError.kt
- com/sn/app/application/port/out/StudentRepositoryPort.kt
- com/sn/app/application/port/out/WelcomeEmailPort.kt
- com/sn/app/adapter/out/persistence/StudentPersistenceAdapter.kt
- com/sn/app/adapter/out/notification/WelcomeEmailAdapter.kt
- com/sn/app/adapter/in/web/StudentController.kt
- com/sn/app/application/usecase/RegisterStudentServiceTest.kt
Files:
- (full contents for each file)

## Tests
- [ ] Test case 1: Requirement with only DB write -> generates InPort + UseCase + OutPort(persistence) + persistence adapter + unit test.
- [ ] Test case 2: Requirement with external HTTP call only -> generates OutPort(client) + client adapter, no JPA stubs unless requested.
- [ ] Test case 3: Existing InPort file already present -> outputs unified diff and does not overwrite in dry-run.
