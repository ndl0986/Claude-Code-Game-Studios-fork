# Coding conventions (Swift, `apple/`)

> **Status:** Active (TASK-131, 2026-11-20). Linked from `control-manifest.md` § Global Rules.
> **Why this file exists:** the technical-setup → pre-production gate (2026-11-20) found no naming conventions
> documented; `project.yaml` has no `naming.*` keys (no Swift engine row) and `technical-preferences.md` is
> unconfigured. These rules describe what the code in `apple/` already does, so they are checkable against it.
> The shared `CLAUDE.md` template is not edited for this.

Each rule is checkable by reading a file name, a declaration or a test name. "Source" is where the rule comes from:
the Swift API Design Guidelines (swift.org/documentation/api-design-guidelines), an ADR decision, or the existing
code (the convention already in use, recorded here so new code follows it).

## 1. Types, functions and values

| # | Rule | Example | Source |
|---|---|---|---|
| N1 | Types and protocols are **UpperCamelCase**; protocols that describe a capability read as nouns or `-ing`/`-able` adjectives | `SettingsStore`, `enum StageLayer`, `protocol UptimeClock` | API Design Guidelines |
| N2 | Functions, methods, properties, variables and enum cases are **lowerCamelCase** | `func now()`, `case empty` | API Design Guidelines |
| N3 | Name for the call site: argument labels make the call read as a phrase; omit needless words; no type names in names | `insert(_:at:)`, not `insertElement(_:atIndex:)` (Guidelines example) | API Design Guidelines |
| N4 | Mutating/non-mutating pairs follow `sort()` / `sorted()`; Boolean properties read as assertions | `childLockActive` | API Design Guidelines |
| N5 | Constants are `let` with lowerCamelCase; no `k`-prefix, no SCREAMING_CASE | `let stageWidth = 1280.0` | API Design Guidelines |
| N6 | Acronyms are uniformly cased: all-caps inside a name, all-lower at the start | `SVGPath` (type), `svgPath` (value) | API Design Guidelines |
| N7 | **Gameplay values are data, not literals** in code: a tunable number lives in the content/data files ADR-0003 ships (`data/`), read through the loader | — | coding-standards.md; ADR-0003 D1 |

## 2. Files

| # | Rule | Example | Source |
|---|---|---|---|
| F1 | One primary type per file; the file is named after it, **UpperCamelCase.swift** | `SettingsStore.swift`, `StageFit.swift` | existing code |
| F2 | A file of several small related types or helpers is named for the concept | `Seams.swift`, `Helpers.swift`, `Clocks.swift` | existing code |
| F3 | Extensions in their own file: `Type+Concern.swift` | none in `apple/` yet | Swift convention |
| F4 | The app entry point is `<Product>App.swift`; a command-line tool's is `main.swift` | `LetterMorphApp.swift`, `kidtools/main.swift` | existing code |

## 3. Packages, modules and targets

| # | Rule | Example | Source |
|---|---|---|---|
| M1 | Swift packages and library modules are **UpperCamelCase**, one word, ending in what they are (`Core`, `Kit`) | `KidCore`, `MorphCore`, `ContractKit`, `ToolsCore` | existing code; ADR-0002 (module list) |
| M2 | An executable target is **lowercase** (it is a command name) | `kidtools` | existing code |
| M3 | The app's **Swift module stays `LetterMorph`**; the product (the `.app`, menu bar, Finder) is **`Letterlings`** (`PRODUCT_NAME = Letterlings`, `PRODUCT_MODULE_NAME = LetterMorph`); `@testable import LetterMorph` | `Letterlings.app` | TASK-130 (K-04) |
| M4 | Bundle IDs are reverse-DNS, lowercase, under `com.galaxyandsun.letterlings` (`.tests`, `.uitests`, `.preview` suffixes) | `com.galaxyandsun.letterlings.tests` | TASK-130 |
| M5 | New modules or dependencies between them follow ADR-0002's module graph; no new module without an ADR edit | — | ADR-0002 |

## 4. Tests

| # | Rule | Example | Source |
|---|---|---|---|
| T1 | A test target is `<Module>Tests` (UI tests: `<App>UITests`); contract tests live in `ContractTests` | `KidCoreTests`, `MorphCoreTests`, `LetterMorphUITests` | existing code; ADR-0004 |
| T2 | A test file is `<Subject>Tests.swift` | `StageFitTests.swift`, `ContentValidatorTests.swift` | existing code |
| T3 | XCTest method names are **`test_` + a lower-case snake_case sentence** stating the behaviour, so a failure reads as a claim | `test_a_wrong_case_file_fails_V7`, `test_app_launches_to_the_title` | existing code |
| T4 | A rule or acceptance-criterion id in a test name keeps its own case | `…_fails_V7` (validator rule V7) | existing code |
| T5 | Tests are deterministic: no wall clock, no unseeded randomness; inject the seams (`UptimeClock`, `RandomSource`) | `DrawList: RandomSource` | coding-standards.md; ADR-0002 (seams) |

## 5. Assets and content ids (pointers, not restated)

- **Content ids, file stems and paths:** Key Table & Theme Data **V6** (`design/gdd/key-table-theme-data.md`: the
  `castId` pattern, `cast/`, `sil/` and `sfx` naming with the theme's `assetPrefix`) and **ADR-0003 D1** (the bundle
  layout; paths relative, lowercase, forward slashes, exact case). Do not restate or vary them in code: read ids from
  theme data, never build them from string literals.
- **Art file naming:** art bible §8 (referenced by V6).
- **Fixtures:** ADR-0004 (fixture names and the harness).

## 6. When this file changes

A convention that changes code already written is a team decision (leader → Luan if it affects shipped names, e.g.
M3/M4). Add the rule here with its source, then regenerate `control-manifest.md` (it links here, it does not copy).
